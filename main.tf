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
  dev_url               = "https://webapp--main--${local.workspace_name}--${local.user_username}.embold.dev"
  mariadb_version       = data.coder_parameter.mariadb_version.value
  mariadb_auto_upgrade  = data.coder_parameter.mariadb_auto_upgrade.value ? "1" : "0"
  php_version           = data.coder_parameter.php_version.value
  pulsar_app_name       = data.coder_parameter.pulsar_app_name.value
  pulsar_magic_template = data.coder_parameter.pulsar_magic_template.value
  ubuntu_version        = data.coder_parameter.ubuntu_version.value
  user_email            = data.coder_workspace_owner.me.email
  user_full_name        = coalesce(data.coder_workspace_owner.me.full_name, local.user_username)
  user_id               = data.coder_workspace_owner.me.id
  user_username         = lower(data.coder_workspace_owner.me.name)
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = lower(data.coder_workspace.me.name)
}

variable "DOCKER_REGISTRY_PASS" {
  sensitive = true
}

data "coder_parameter" "pulsar_app_name" {
  name        = "Pulsar App Name"
  description = "What is the Pulsar app name? If this is blank, the workspace name will be used."
  icon        = "/icon/coder.svg"
  type        = "string"
  default     = ""
  mutable     = true
}

data "coder_parameter" "pulsar_magic_template" {
  name        = "Pulsar Magic Template?"
  description = "Should we use the Pulsar magic template to dynamically build the Pulsar configuration?"
  type        = "bool"
  # font-awesome icon for a magic wand
  icon    = "data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%20576%20512%22%3E%3C!--!Font%20Awesome%20Free%206.7.1%20by%20%40fontawesome%20-%20https%3A%2F%2Ffontawesome.com%20License%20-%20https%3A%2F%2Ffontawesome.com%2Flicense%2Ffree%20Copyright%202024%20Fonticons%2C%20Inc.--%3E%3Cpath%20d%3D%22M234.7%2042.7L197%2056.8c-3%201.1-5%204-5%207.2s2%206.1%205%207.2l37.7%2014.1L248.8%20123c1.1%203%204%205%207.2%205s6.1-2%207.2-5l14.1-37.7L315%2071.2c3-1.1%205-4%205-7.2s-2-6.1-5-7.2L277.3%2042.7%20263.2%205c-1.1-3-4-5-7.2-5s-6.1%202-7.2%205L234.7%2042.7zM46.1%20395.4c-18.7%2018.7-18.7%2049.1%200%2067.9l34.6%2034.6c18.7%2018.7%2049.1%2018.7%2067.9%200L529.9%20116.5c18.7-18.7%2018.7-49.1%200-67.9L495.3%2014.1c-18.7-18.7-49.1-18.7-67.9%200L46.1%20395.4zM484.6%2082.6l-105%20105-23.3-23.3%20105-105%2023.3%2023.3zM7.5%20117.2C3%20118.9%200%20123.2%200%20128s3%209.1%207.5%2010.8L64%20160l21.2%2056.5c1.7%204.5%206%207.5%2010.8%207.5s9.1-3%2010.8-7.5L128%20160l56.5-21.2c4.5-1.7%207.5-6%207.5-10.8s-3-9.1-7.5-10.8L128%2096%20106.8%2039.5C105.1%2035%20100.8%2032%2096%2032s-9.1%203-10.8%207.5L64%2096%207.5%20117.2zm352%20256c-4.5%201.7-7.5%206-7.5%2010.8s3%209.1%207.5%2010.8L416%20416l21.2%2056.5c1.7%204.5%206%207.5%2010.8%207.5s9.1-3%2010.8-7.5L480%20416l56.5-21.2c4.5-1.7%207.5-6%207.5-10.8s-3-9.1-7.5-10.8L480%20352l-21.2-56.5c-1.7-4.5-6-7.5-10.8-7.5s-9.1%203-10.8%207.5L416%20352l-56.5%2021.2z%22%2F%3E%3C%2Fsvg%3E"
  default = false
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

data "coder_parameter" "mariadb_auto_upgrade" {
  name        = "MariaDB Auto Upgrade"
  description = "Should MariaDB automatically upgrade the database schema? Set this to true if the MariaDB version has changed since the last workspace build."  
  icon        = "/icon/database.svg"
  type        = "bool"
  default     = false
  mutable     = true
  ephemeral   = true
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
    APP                   = local.app
    CODER_USERNAME        = local.user_username
    CODER_WORKSPACE_NAME  = local.workspace_name
    CODER_WORKSPACE_PORT  = 443
    DEVURL                = local.dev_url
    GIT_AUTHOR_NAME       = local.user_full_name
    GIT_AUTHOR_EMAIL      = local.user_email
    GIT_COMMITTER_NAME    = local.user_full_name
    GIT_COMMITTER_EMAIL   = local.user_email
    PULSAR_MAGIC_TEMPLATE = local.pulsar_magic_template
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
  count = data.coder_workspace.me.start_count
}

resource "docker_container" "mysql" {
  count        = data.coder_workspace.me.start_count
  name         = "coder-${local.user_username}-${local.workspace_name}-mysql"
  image        = "mariadb:${local.mariadb_version}"
  hostname     = "mysql"
  network_mode = docker_network.workspace[count.index].name
  env = [
    "MYSQL_ROOT_PASSWORD=embold",
    "MYSQL_DATABASE=${local.db_name}",
    "MYSQL_USER=embold",
    "MYSQL_PASSWORD=embold",
    "MARIADB_AUTO_UPGRADE=${local.mariadb_auto_upgrade}"
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
  count      = data.coder_workspace.me.start_count
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
  network_mode = docker_network.workspace[count.index].name
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
  count       = data.coder_workspace.me.start_count
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
