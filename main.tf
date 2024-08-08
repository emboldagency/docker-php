terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 1.0.1"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  registry_auth {
    address  = "registry-1.docker.io"
    username = "emboldcreative"
    password = var.DOCKER_REGISTRY_PASS
  }
}

data "coder_provisioner" "me" {}

data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}


locals {
  app                   = lower(try(length(local.pulsar_app_name), 0) > 0 ? local.pulsar_app_name : local.workspace_name)
  db_name               = replace(local.app, "-", "_")
  dev_url                = "https://webapp--main--${local.workspace_name}--${local.user_username}.embold.dev"
  mariadb_version       = data.coder_parameter.mariadb_version.value
  network_mode          = docker_network.workspace[count.index].name
  php_version           = data.coder_parameter.php_version.value
  pulsar_app_name       = data.coder_parameter.pulsar_app_name.value
  ubuntu_version        = data.coder_parameter.ubuntu_version.value
  user_email            = data.coder_workspace_owner.me.email
  user_full_name        = coalesce(data.coder_workspace_owner.me.full_name, local.user_username)
  user_id               = data.coder_workspace_owner.id
  user_username         = lower(data.coder_workspace_owner.me.name)
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = lower(data.coder_workspace.me.name)
  workspace_start_count = data.coder_workspace.me.start_count
}

variable "DOCKER_REGISTRY_PASS" {
  sensitive = true
}

data "coder_parameter" "pulsar_app_name" {
  name        = "Pulsar App Name"
  description = "What is the pulsar app name? If this is blank, the workspace name will be used."
  icon        = "/icon/coder.svg"
  type        = "string"
  default     = ""
  mutable     = true
}

data "coder_parameter" "php_version" {
  name        = "PHP Version"
  description = "Which version of PHP? Must match a emboldcreative/php image tag on DockerHub"
  icon        = "/icon/php.svg"
  type        = "string"
  default     = "8.3"
  mutable     = true
}

data "coder_parameter" "mariadb_version" {
  name        = "MariaDB Version"
  description = "What version of MariaDB? Must match an official mariadb image tag on DockerHub"
  icon        = "/icon/database.svg"
  type        = "string"
  default     = "10.11"
  mutable     = true
}

data "coder_parameter" "ubuntu_version" {
  name        = "Ubuntu Version"
  description = "Which version of Ubuntu? Must match a emboldcreative/base image tag on DockerHub"
  icon        = "/icon/ubuntu.svg"
  type        = "string"
  default     = "24.04"
  mutable     = true
}

resource "coder_agent" "main" {
  arch                    = data.coder_provisioner.me.arch
  os                      = "linux"
  startup_script_behavior = "blocking"
  env = {
    APP                  = local.app
    CODER_USERNAME       = local.user_username
    CODER_WORKSPACE_NAME = local.workspace_name
    CODER_WORKSPACE_PORT = 443
    DEVURL               = local.dev_url
    GIT_AUTHOR_NAME      = local.user_full_name
    GIT_AUTHOR_EMAIL     = local.user_email
    GIT_COMMITTER_NAME   = local.user_full_name
    GIT_COMMITTER_EMAIL  = local.user_email
  }
  startup_script = <<-EOT
        set -e
        /bin/bash /coder/scripts/configure
    EOT
}

resource "docker_volume" "home_volume" {
  name = "coder-${local.user_username}-${local.workspace_name}-${local.workspace_id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = local.user_username
  }
  labels {
    label = "coder.owner_id"
    value = local.user_id
  }
  labels {
    label = "coder.workspace_id"
    value = local.workspace_id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = local.workspace_name
  }
}

resource "docker_volume" "mysql_volume" {
  name = "coder-${local.user_username}-${local.workspace_name}-${local.workspace_id}-mysql"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = local.user_username
  }
  labels {
    label = "coder.owner_id"
    value = local.user_id
  }
  labels {
    label = "coder.workspace_id"
    value = local.workspace_id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = local.workspace_name
  }
}

resource "docker_network" "workspace" {
  name  = "coder-${local.user_username}-${local.workspace_name}-network"
  count = local.workspace_start_count
}

resource "docker_container" "mysql" {
  count        = local.workspace_start_count
  name         = "coder-${local.user_username}-${local.workspace_name}-mysql"
  image        = "mariadb:${local.mariadb_version}"
  hostname     = "mysql"
  network_mode = local.network_mode
  env = [
    "MYSQL_ROOT_PASSWORD=embold",
    "MYSQL_DATABASE=${local.db_name}",
    "MYSQL_USER=embold",
    "MYSQL_PASSWORD=embold",
  ]
  volumes {
    container_path = "/var/lib/mysql"
    volume_name    = docker_volume.mysql_volume.name
    read_only      = false
  }
}

data "docker_registry_image" "php" {
  name = "emboldcreative/php:${local.php_version}-ubuntu${local.ubuntu_version}"
}

resource "docker_image" "php" {
  name          = data.docker_registry_image.php.name
  pull_triggers = [data.docker_registry_image.php.sha256_digest]
  keep_locally  = true
}

resource "docker_container" "workspace" {
  count      = local.workspace_start_count
  image      = docker_image.php.name
  name       = "coder-${local.user_username}-${local.workspace_name}"
  hostname   = local.workspace_name
  entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "HOSTNAME=${local.app}",
    "MYSQL_HOST=mysql",
    "MYSQL_DATABASE=${local.db_name}",
    "MYSQL_USER=embold",
    "MYSQL_PASSWORD=embold"
  ]
  volumes {
    container_path = "/home/embold"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  network_mode = local.network_mode
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = local.user_username
  }
  labels {
    label = "coder.owner_id"
    value = local.user_id
  }
  labels {
    label = "coder.workspace_id"
    value = local.workspace_id
  }
  labels {
    label = "coder.workspace_name"
    value = local.workspace_name
  }
}

resource "coder_app" "web_app" {
  agent_id     = coder_agent.main.id
  display_name = "Web App"
  slug         = "webapp"
  icon         = "/emojis/1f310.png"
  url          = "http://localhost:443"
  subdomain    = true
  share        = "public"
}

resource "coder_metadata" "container_info" {
  count       = local.workspace_start_count
  resource_id = docker_container.workspace[0].id

  item {
    key   = "image"
    value = basename(docker_image.php.name)
  }
  item {
    key   = "dev_url"
    value = local.dev_url
  }
  item {
    key   = "php_version"
    value = local.php_version
  }
}

module "code-server" {
  display_name = "VS Code Web"
  source       = "https://registry.coder.com/modules/code-server"
  agent_id     = coder_agent.main.id
  folder       = "/home/embold/code/${local.app}"
  extensions   = []
  settings = {
    "workbench.colorTheme" : "Default Dark Modern"
  }
}

module "jetbrains_gateway" {
  source         = "https://registry.coder.com/modules/jetbrains-gateway"
  agent_id       = coder_agent.main.id
  agent_name     = local.workspace_name
  folder         = "/home/embold/code/${local.app}"
  jetbrains_ides = ["PS"]
  default        = "PS"
}
