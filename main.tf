terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.18.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "coder" {
}

provider "docker" {
  registry_auth {
    address  = "registry-1.docker.io"
    username = "emboldcreative"
    password = var.DOCKER_REGISTRY_PASS
  }
}

data "coder_provisioner" "me" {
}

data "coder_workspace" "me" {
}

locals {
  devurl  = "https://webapp--main--${lower(data.coder_workspace.me.name)}--${lower(data.coder_workspace.me.owner)}.embold.dev"
  app     = try(length(data.coder_parameter.pulsar_app_name.value), 0) > 0 ? lower(data.coder_parameter.pulsar_app_name.value) : lower(data.coder_workspace.me.name)
  db_name = replace(local.app, "-", "_")
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
  description = "Which version of PHP?"
  icon        = "/icon/php.svg"
  type        = "string"
  default     = "8.1"
  mutable     = true

  option {
    name  = "8.3"
    value = "8.3"
  }

  option {
    name  = "8.2"
    value = "8.2"
  }

  option {
    name  = "8.1"
    value = "8.1"
  }

  option {
    name  = "7.4"
    value = "7.4"
  }
}

data "coder_parameter" "mariadb_version" {
  name        = "MariaDB Version"
  description = "What version of MariaDB is the database? Should match a DockerHub tag for the MariaDB image"
  icon        = "/icon/database.svg"
  type        = "string"
  default     = "10.4"
  mutable     = true
}

data "coder_parameter" "ubuntu_version" {
  name        = "Ubuntu Version"
  description = "Which version of Ubuntu?"
  icon        = "/icon/ubuntu.svg"
  type        = "string"
  default     = "22.04"
  mutable     = true

  # option {
  #   name  = "24.04 LTS (Noble)"
  #   value = "24.04"
  # }

  option {
    name  = "22.04 LTS (Jammy)"
    value = "22.04"
  }
}

resource "coder_agent" "main" {
  arch                    = data.coder_provisioner.me.arch
  os                      = "linux"
  startup_script_behavior = "blocking"
  env = {
    "APP"                  = local.app
    "CODER_USERNAME"       = data.coder_workspace.me.owner
    "CODER_WORKSPACE_NAME" = data.coder_workspace.me.name
    "CODER_WORKSPACE_PORT" = 443
    "DEVURL"               = local.devurl
    "GIT_AUTHOR_EMAIL"     = data.coder_workspace.me.owner_email
    "GIT_AUTHOR_NAME"      = data.coder_workspace.me.owner
    "GIT_COMMITTER_EMAIL"  = data.coder_workspace.me.owner_email
    "GIT_COMMITTER_NAME"   = data.coder_workspace.me.owner
  }
  startup_script = <<-EOT
        set -e
        /bin/bash /coder/scripts/configure
    EOT
}

resource "docker_volume" "home_volume" {
  name = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_volume" "mysql_volume" {
  name = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}-${data.coder_workspace.me.id}-mysql"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_network" "workspace" {
  name  = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}-network"
  count = data.coder_workspace.me.start_count
}

resource "docker_container" "mysql" {
  count        = data.coder_workspace.me.start_count
  name         = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}-mysql"
  image        = "mariadb:${data.coder_parameter.mariadb_version.value}"
  hostname     = "mysql"
  network_mode = docker_network.workspace[count.index].name
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
  name = "emboldcreative/php:${data.coder_parameter.php_version.value}-ubuntu${data.coder_parameter.ubuntu_version.value}"
}

resource "docker_image" "php" {
  name          = data.docker_registry_image.php.name
  pull_triggers = [data.docker_registry_image.php.sha256_digest]
  keep_locally  = true
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.php.name
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name
  # Use the docker gateway if the access URL is 127.0.0.1
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
    value = data.coder_workspace.me.owner
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace.me.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
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
    key   = "devurl"
    value = local.devurl
  }
  item {
    key   = "php_version"
    value = data.coder_parameter.php_version.value
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
  agent_name     = data.coder_workspace.me.name
  folder         = "/home/embold/code/${local.app}"
  jetbrains_ides = ["PS"]
  default        = "PS"
}
