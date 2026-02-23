terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 2.13"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6"
    }
  }
}

# ------------------------------------------------------------------------------
# Providers
# ------------------------------------------------------------------------------

provider "coder" {}

provider "docker" {
  registry_auth {
    address  = "ghcr.io"
    username = "emboldagency"
    password = var.GHP_REGISTRY_PASS
  }
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

variable "GHP_REGISTRY_PASS" {
  sensitive = true
}

# ------------------------------------------------------------------------------
# Coder Parameters
# ------------------------------------------------------------------------------


data "coder_parameter" "pulsar_app_name" {
  name        = "Pulsar App Name"
  description = "What is the Pulsar app name? If this is blank, the workspace name will be used."
  icon        = "https://api.embold.net/icons/?name=title.svg&color=009dff"
  type        = "string"
  default     = ""
  mutable     = true
  order       = 1
}

data "coder_parameter" "pulsar_magic_template" {
  name        = "Pulsar Magic Template?"
  description = "Should we use the Pulsar magic template to dynamically build the Pulsar configuration?"
  type        = "bool"
  icon        = "https://api.embold.net/icons/?name=fas-magic-wand.svg&color=009dff"
  default     = false
  mutable     = true
  order       = 2
}

data "coder_parameter" "php_version" {
  name        = "PHP Version"
  description = "Which version of PHP? Must match a [ghcr.io/emboldagency/docker-php](https://github.com/emboldagency/docker-php/pkgs/container/docker-php) image tag."
  icon        = "/icon/php.svg"
  type        = "string"
  default     = "8.3"
  mutable     = true
  order       = 3
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
  validation {
    regex = "^(8\\.4|8\\.3|8\\.2|8\\.1|7\\.4)$"
    error = "PHP version must be one of: 8.4, 8.3, 8.2, 8.1, or 7.4. See available versions at https://github.com/emboldagency/docker-php/pkgs/container/docker-php"
  }
}

data "coder_parameter" "mariadb_version" {
  name        = "MariaDB Version"
  description = "What version of MariaDB? Must match a [mariadb](https://hub.docker.com/_/mariadb) image tag."
  icon        = "https://api.embold.net/icons/?name=mariadb.svg"
  type        = "string"
  default     = "12.1"
  mutable     = true
  order       = 4
}

data "coder_parameter" "mariadb_auto_upgrade" {
  name        = "MariaDB Auto Upgrade"
  description = "Should MariaDB automatically upgrade the database schema? Set this to true if the MariaDB version has changed since the last workspace build."
  icon        = "https://api.embold.net/icons/?name=mariadb.svg"
  type        = "bool"
  default     = false
  mutable     = true
  order       = 5
}

data "coder_parameter" "ubuntu_version" {
  name        = "Ubuntu Version"
  description = "Which version of Ubuntu? Must match an available [docker-base image tag](https://github.com/emboldagency/docker-base/pkgs/container/docker-base)."
  icon        = "/icon/ubuntu.svg"
  type        = "string"
  default     = "24.04"
  mutable     = true
  order       = 6
  option {
    name  = "24.04 LTS (Noble)"
    value = "24.04"
  }
  validation {
    regex = "^(24\\.04)$"
    error = "Ubuntu version must be 24.04. See available versions at https://github.com/emboldagency/docker-base/pkgs/container/docker-base"
  }
}

# ------------------------------------------------------------------------------
# Context Data & Locals
# ------------------------------------------------------------------------------

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

data "coder_external_auth" "github" {
  id = "github"
}

locals {
  app                   = lower(try(length(local.pulsar_app_name), 0) > 0 ? local.pulsar_app_name : local.workspace_name)
  db_name               = replace(local.app, "-", "_")
  dev_url               = "https://webapp--${local.workspace_name}--${local.user_username}.embold.dev"
  dotfiles_uri          = try(module.dotfiles_link[0].dotfiles_uri, "")
  github_token          = data.coder_external_auth.github.access_token
  mariadb_version       = data.coder_parameter.mariadb_version.value
  mariadb_auto_upgrade  = data.coder_parameter.mariadb_auto_upgrade.value ? "1" : "0"
  php_version           = data.coder_parameter.php_version.value
  pulsar_app_name       = data.coder_parameter.pulsar_app_name.value
  pulsar_magic_template = data.coder_parameter.pulsar_magic_template.value
  template_version      = "2026.02.23.0"
  timezone              = coalesce(module.timezone.timezone, "UTC")
  ubuntu_version        = data.coder_parameter.ubuntu_version.value
  user_email            = data.coder_workspace_owner.me.email
  user_full_name        = coalesce(data.coder_workspace_owner.me.full_name, local.user_username)
  user_id               = data.coder_workspace_owner.me.id
  user_username         = lower(data.coder_workspace_owner.me.name)
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = lower(data.coder_workspace.me.name)
}

# ------------------------------------------------------------------------------
# Main Resources
# ------------------------------------------------------------------------------

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
    DOTFILES_URL          = local.dotfiles_uri
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
    script       = "mariadb -N -e \"SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) FROM information_schema.tables;\" 2>/dev/null | awk '{print $1 \"G\"}'"
    interval     = 300
    timeout      = 30
    order        = 4
  }

  startup_script = <<-EOT
    set -e
    /bin/bash /coder/scripts/configure
  EOT
}

resource "coder_app" "web_app" {
  agent_id     = coder_agent.main.id
  display_name = "Web App"
  slug         = "webapp"
  icon         = "https://api.embold.net/icons/?name=fas-globe.svg&color=009dff"
  url          = "http://localhost:443"
  subdomain    = true
  share        = "public"
  order        = 1
  open_in      = "tab"
}

# ------------------------------------------------------------------------------
# Networking & Volumes
# ------------------------------------------------------------------------------

resource "docker_network" "workspace" {
  count = data.coder_workspace.me.start_count
  name  = "coder-${local.user_username}-${local.workspace_name}-network"
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

# ------------------------------------------------------------------------------
# Containers
# ------------------------------------------------------------------------------

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
  name = "ghcr.io/emboldagency/docker-php:${local.php_version}-ubuntu${local.ubuntu_version}-release${local.template_version}"
}

resource "docker_image" "php" {
  name          = data.docker_registry_image.php.name
  pull_triggers = [data.docker_registry_image.php.sha256_digest]
  keep_locally  = true
}

resource "docker_container" "workspace" {
  count        = data.coder_workspace.me.start_count
  name         = "coder-${local.user_username}-${local.workspace_name}"
  image        = docker_image.php.name
  hostname     = local.workspace_name
  entrypoint   = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  network_mode = docker_network.workspace[count.index].name

  env = [
    "APP=${local.app}",
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "GITHUB_TOKEN=${local.github_token}",
    "HOSTNAME=${local.app}",
    "MYSQL_HOST=mysql",
    "MYSQL_DATABASE=${local.db_name}",
    "MYSQL_USER=embold",
    "MYSQL_PASSWORD=embold",
    "PULSAR_APP_NAME=${local.pulsar_app_name}",
    "TZ=${local.timezone}"
  ]

  volumes {
    container_path = "/home/embold"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
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
  labels {
    label = "coder.workspace_name"
    value = local.workspace_name
  }
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
    value = basename(docker_image.php.name)
  }

  dynamic "item" {
    for_each = module.dynamic_services[0].connection_metadata
    content {
      key   = "Hostname (custom-${item.value.custom_index}, ${split(":", item.value.image)[0]})"
      value = item.value.hostname
    }
  }
}

# ------------------------------------------------------------------------------
# Modules
# ------------------------------------------------------------------------------

module "adminer" {
  source              = "git::https://github.com/emboldagency/coder-registry.git//modules/adminer?ref=main"
  count               = data.coder_workspace.me.start_count
  agent_id            = coder_agent.main.id
  docker_network_name = docker_network.workspace[0].name
  resource_name_base  = "coder-${local.user_username}-${local.workspace_name}"
  db_server           = "mysql"
  db_username         = "embold"
  db_password         = "embold"
  db_name             = local.db_name
  db_driver           = "server"
  proxy_mappings      = ["18080:adminer:8080"]
}

module "code-server" {
  source       = "https://registry.coder.com/modules/code-server"
  agent_id     = coder_agent.main.id
  folder       = "/home/embold/code/${local.app}"
  display_name = "VS Code Web"
  extensions   = []
  settings = {
    "workbench.colorTheme" : "Default Dark Modern"
  }
}

  source          = "git::https://github.com/emboldagency/coder-registry.git//modules/dotfiles?ref=main"
  count           = data.coder_workspace.me.start_count
  agent_id        = coder_agent.main.id
  user            = "embold"
  parameter_order = 10 # 3 parameters
}

module "dynamic_services" {
  source              = "git::https://github.com/emboldagency/coder-registry.git//modules/dynamic-resources?ref=main"
  count               = data.coder_workspace.me.start_count
  agent_id            = coder_agent.main.id
  docker_network_name = docker_network.workspace[0].name
  resource_name_base  = "coder-${local.user_username}-${local.workspace_name}"
  parameter_order     = 30 # 34 parameters (pushed towards end)
}

module "home_setup" {
  source     = "git::https://github.com/emboldagency/coder-registry.git//modules/home-setup?ref=main"
  count      = data.coder_workspace.me.start_count
  agent_id   = coder_agent.main.id
  source_dir = "/coder/home"
  target_dir = "/home/embold"
}

module "jetbrains_gateway" {
  source         = "https://registry.coder.com/modules/jetbrains-gateway"
  agent_id       = coder_agent.main.id
  agent_name     = local.workspace_name
  folder         = "/home/embold/code/${local.app}"
  jetbrains_ides = ["PS"]
  default        = "PS"
}

module "antigravity" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/antigravity/coder"
  version  = "1.0.0"
  agent_id = coder_agent.main.id
}

module "mailpit" {
  source              = "git::https://github.com/emboldagency/coder-registry.git//modules/mailpit?ref=main"
  count               = data.coder_workspace.me.start_count
  agent_id            = coder_agent.main.id
  docker_network_name = docker_network.workspace[0].name
  resource_name_base  = "coder-${local.user_username}-${local.workspace_name}"
  proxy_mappings      = ["18025:mailpit:8025"]
}

module "ssh_setup" {
  source   = "git::https://github.com/emboldagency/coder-registry.git//modules/ssh-setup?ref=main"
  count    = data.coder_workspace.me.start_count
  agent_id = coder_agent.main.id
  hosts = [
    "github.com",
    "embold.net",
    "coder.ssh.embold.net:2022",
    "8.42.149.40:2022",
    "maintenance.ssh.embold.net:3022",
    "8.42.149.40:3022",
    "staging.ssh.embold.net:22",
    "8.42.149.41:22",
  ]
}

module "timezone" {
  source          = "git::https://github.com/emboldagency/coder-registry.git//modules/timezone?ref=main"
  agent_id        = coder_agent.main.id
  parameter_order = 7 # 1 parameter
}
