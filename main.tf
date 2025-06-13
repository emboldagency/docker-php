terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 2.5.3"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.1"
    }
  }
}

provider "coder" {}

data "coder_external_auth" "github" {
  id = "github"
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
  dotfiles_url          = data.coder_parameter.dotfiles_url.value
  github_token          = data.coder_external_auth.github.access_token
  mariadb_version       = data.coder_parameter.mariadb_version.value
  mariadb_auto_upgrade  = data.coder_parameter.mariadb_auto_upgrade.value ? "1" : "0"
  php_version           = data.coder_parameter.php_version.value
  pulsar_app_name       = data.coder_parameter.pulsar_app_name.value
  pulsar_magic_template = data.coder_parameter.pulsar_magic_template.value
  template_version      = "v1.6.1"
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

data "coder_parameter" "dotfiles_url" {
  name        = "dotfiles URL"
  description = "GitHub repository with dotfiles"
  mutable     = true
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
  icon        = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 576 512'%3E%3C!--!Font Awesome Free 6.7.1 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2024 Fonticons, Inc.--%3E%3Cpath fill='%23009dff' d='M234.7 42.7L197 56.8c-3 1.1-5 4-5 7.2s2 6.1 5 7.2l37.7 14.1L248.8 123c1.1 3 4 5 7.2 5s6.1-2 7.2-5l14.1-37.7L315 71.2c3-1.1 5-4 5-7.2s-2-6.1-5-7.2L277.3 42.7 263.2 5c-1.1-3-4-5-7.2-5s-6.1 2-7.2 5L234.7 42.7zM46.1 395.4c-18.7 18.7-18.7 49.1 0 67.9l34.6 34.6c18.7 18.7 49.1 18.7 67.9 0L529.9 116.5c18.7-18.7 18.7-49.1 0-67.9L495.3 14.1c-18.7-18.7-49.1-18.7-67.9 0L46.1 395.4zM484.6 82.6l-105 105-23.3-23.3 105-105 23.3 23.3zM7.5 117.2C3 118.9 0 123.2 0 128s3 9.1 7.5 10.8L64 160l21.2 56.5c1.7 4.5 6 7.5 10.8 7.5s9.1-3 10.8-7.5L128 160l56.5-21.2c4.5-1.7 7.5-6 7.5-10.8s-3-9.1-7.5-10.8L128 96 106.8 39.5C105.1 35 100.8 32 96 32s-9.1 3-10.8 7.5L64 96 7.5 117.2zm352 256c-4.5 1.7-7.5 6-7.5 10.8s3 9.1 7.5 10.8L416 416l21.2 56.5c1.7 4.5 6 7.5 10.8 7.5s9.1-3 10.8-7.5L480 416l56.5-21.2c4.5-1.7 7.5-6 7.5-10.8s-3-9.1-7.5-10.8L480 352l-21.2-56.5c-1.7-4.5-6-7.5-10.8-7.5s-9.1 3-10.8 7.5L416 352l-56.5 21.2z'/%3E%3C/svg%3E" # font-awesome magic wand. alt: "/emojis/1fa84.png"
  default     = false
  mutable     = true
}

data "coder_parameter" "php_version" {
  name        = "PHP Version"
  description = "Which version of PHP? Must match a emboldcreative/php image tag on DockerHub"
  icon        = "/icon/php.svg"
  type        = "string"
  default     = "8.3"
  mutable     = true
  option {
    name  = "8.4"
    value = "8.4"
  }
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
  option {
    name  = "24.04 LTS (Noble)"
    value = "24.04"
  }
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
    APP                   = local.app
    CODER_USERNAME        = local.user_username
    CODER_WORKSPACE_NAME  = local.workspace_name
    CODER_WORKSPACE_PORT  = 443
    DEVURL                = local.dev_url
    DOTFILES_URL          = local.dotfiles_url
    GIT_AUTHOR_NAME       = local.user_full_name
    GIT_AUTHOR_EMAIL      = local.user_email
    GIT_COMMITTER_NAME    = local.user_full_name
    GIT_COMMITTER_EMAIL   = local.user_email
    PULSAR_MAGIC_TEMPLATE = local.pulsar_magic_template
  }
  metadata {
    display_name = "CPU Usage"
    key          = "cpu"
    script       = "coder stat cpu"
    interval     = 30
    timeout      = 1
    order        = 1
  }
  metadata {
    display_name = "Memory Usage"
    key          = "mem"
    script       = "coder stat mem --prefix 'Gi' | sed 's/ //;s/iB//'"
    interval     = 30
    timeout      = 1
    order        = 2
  }
  metadata {
    display_name = "Home Volume Size"
    key          = "home_volume_size"
    script       = "du -BG --apparent-size /home/embold | tail -1 | awk '{print $1}'"
    interval     = 300
    timeout      = 30
    order        = 3
  }
  metadata {
    display_name = "Database Size"
    key          = "mysql_volume_size"
    script       = "mariadb -N -e \"SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) FROM information_schema.tables;\" 2>/dev/null | awk '{print $1 \" GiB\"}'"
    interval     = 300
    timeout      = 30
    order        = 4
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
  name = "emboldcreative/php:${local.php_version}-ubuntu${local.ubuntu_version}-${local.template_version}"
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
    "GITHUB_TOKEN=${local.github_token}",
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
    key   = "PHP"
    value = local.php_version
  }
  item {
    key   = "MariaDB"
    value = local.mariadb_version
  }
  item {
    key   = "Ubuntu"
    value = local.ubuntu_version
  }
  item {
    key   = "Image"
    value = "[${basename(docker_image.php.name)}](https://hub.docker.com/r/${split("/", docker_image.php.name)[0]}/${split(":", split("/", docker_image.php.name)[1])[0]}/tags?name=${split(":", docker_image.php.name)[1]})"
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
