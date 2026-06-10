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
  name         = "php_version"
  display_name = "PHP Version"
  description  = "Which version of PHP? Must match a [ghcr.io/emboldagency/docker-php](https://github.com/emboldagency/docker-php/pkgs/container/docker-php) image tag."
  icon         = "/icon/php.svg"
  type         = "string"
  default      = "8.3"
  mutable      = true
  order        = 3
  option {
    name  = "8.5"
    value = "8.5"
  }
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
  name         = "mariadb_version"
  display_name = "MariaDB Version"
  description  = "What version of MariaDB? Must match a [mariadb](https://hub.docker.com/_/mariadb) image tag."
  icon         = "https://api.embold.net/icons/?name=mariadb.svg"
  type         = "string"
  default      = "12.1"
  mutable      = true
  order        = 4
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
  name         = "ubuntu_version"
  display_name = "Ubuntu Version"
  description  = "Which version of Ubuntu? Must match an available [docker-base image tag](https://github.com/emboldagency/docker-base/pkgs/container/docker-base)."
  icon         = "/icon/ubuntu.svg"
  type         = "string"
  default      = "24.04"
  mutable      = true
  order        = 6
  option {
    name  = "24.04 LTS (Noble)"
    value = "24.04"
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
  app                     = lower(try(length(local.pulsar_app_name), 0) > 0 ? local.pulsar_app_name : local.workspace_name)
  db_name                 = replace(local.app, "-", "_")
  dev_url                 = "https://webapp--${local.workspace_name}--${local.user_username}.embold.dev"
  dotfiles_uri            = try(module.dotfiles[0].dotfiles_uri, "")
  github_token            = data.coder_external_auth.github.access_token
  legacy_dotfiles_url     = trimspace(try(data.coder_parameter.dotfiles_url.value, ""))
  legacy_dotfiles_pending = local.legacy_dotfiles_url != "" && local.dotfiles_uri != local.legacy_dotfiles_url
  legacy_mariadb_version  = trimspace(try(data.coder_parameter.mariadb_version_legacy.value, ""))
  legacy_mariadb_pending  = local.legacy_mariadb_version != "" && data.coder_parameter.mariadb_version.value != local.legacy_mariadb_version
  legacy_php_version      = trimspace(try(data.coder_parameter.php_version_legacy.value, ""))
  legacy_php_pending      = local.legacy_php_version != "" && data.coder_parameter.php_version.value != local.legacy_php_version
  legacy_ubuntu_version   = trimspace(try(data.coder_parameter.ubuntu_version_legacy.value, ""))
  legacy_ubuntu_pending   = local.legacy_ubuntu_version != "" && data.coder_parameter.ubuntu_version.value != local.legacy_ubuntu_version
  has_legacy_params       = local.legacy_dotfiles_pending || local.legacy_php_pending || local.legacy_mariadb_pending || local.legacy_ubuntu_pending
  mariadb_version         = data.coder_parameter.mariadb_version.value
  mariadb_auto_upgrade    = data.coder_parameter.mariadb_auto_upgrade.value ? "1" : "0"
  php_version             = data.coder_parameter.php_version.value
  pulsar_app_name         = data.coder_parameter.pulsar_app_name.value
  pulsar_magic_template   = data.coder_parameter.pulsar_magic_template.value
  resource_name_base      = "coder-${local.user_username}-${local.workspace_name}"
  template_version        = trimspace(file("${path.module}/VERSION"))
  timezone                = coalesce(module.timezone.timezone, "UTC")
  ubuntu_version          = data.coder_parameter.ubuntu_version.value
  user_email              = data.coder_workspace_owner.me.email
  user_full_name          = coalesce(data.coder_workspace_owner.me.full_name, local.user_username)
  user_id                 = data.coder_workspace_owner.me.id
  user_username           = lower(data.coder_workspace_owner.me.name)
  workspace_id            = data.coder_workspace.me.id
  workspace_name          = lower(data.coder_workspace.me.name)
}

# ------------------------------------------------------------------------------
# Main Resources
# ------------------------------------------------------------------------------

resource "coder_agent" "main" {
  arch                    = data.coder_provisioner.me.arch
  os                      = "linux"
  startup_script_behavior = "blocking"

  env = {
    APP                    = local.app
    CODER_TEMPLATE_VERSION = local.template_version
    CODER_USERNAME         = local.user_username
    CODER_WORKSPACE_NAME   = local.workspace_name
    CODER_WORKSPACE_PORT   = 443
    DEVURL                 = local.dev_url
    DOTFILES_URL           = local.dotfiles_uri
    GIT_AUTHOR_NAME        = local.user_full_name
    GIT_AUTHOR_EMAIL       = local.user_email
    GIT_COMMITTER_NAME     = local.user_full_name
    GIT_COMMITTER_EMAIL    = local.user_email
    PULSAR_MAGIC_TEMPLATE  = local.pulsar_magic_template
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
  name  = "${local.resource_name_base}-network"
}

resource "docker_volume" "home_volume" {
  name = "${local.resource_name_base}-${local.workspace_id}-home"

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
  name = "${local.resource_name_base}-${local.workspace_id}-mysql"

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
  name         = "${local.resource_name_base}-mysql"
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
  name = "ghcr.io/emboldagency/docker-php:${local.php_version}-ubuntu${local.ubuntu_version}-${local.template_version}"
}

resource "docker_image" "php" {
  name          = data.docker_registry_image.php.name
  pull_triggers = [data.docker_registry_image.php.sha256_digest]
  keep_locally  = true
}

resource "docker_container" "workspace" {
  count        = data.coder_workspace.me.start_count
  name         = local.resource_name_base
  image        = docker_image.php.name
  hostname     = local.workspace_name
  entrypoint   = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  network_mode = docker_network.workspace[count.index].name

  env = compact([
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
  ])

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
    key   = "PHP${local.legacy_php_pending ? " (Legacy)" : ""}"
    value = local.php_version
  }
  item {
    key   = "MariaDB${local.legacy_mariadb_pending ? " (Legacy)" : ""}"
    value = local.mariadb_version
  }
  item {
    key   = "Ubuntu${local.legacy_ubuntu_pending ? " (Legacy)" : ""}"
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

  dynamic "item" {
    for_each = local.has_legacy_params ? [1] : []
    content {
      key   = "Action Required"
      value = "⚠️ Migrate legacy params"
    }
  }
}

# ------------------------------------------------------------------------------
# Modules
# ------------------------------------------------------------------------------

module "adminer" {
  source              = "git::https://github.com/emboldagency/coder-registry.git//modules/adminer?ref=v2026.03.11.0"
  count               = data.coder_workspace.me.start_count
  agent_id            = coder_agent.main.id
  docker_network_name = docker_network.workspace[0].name
  resource_name_base  = local.resource_name_base
  db_server           = "mysql"
  db_username         = "embold"
  db_password         = "embold"
  db_name             = local.db_name
  db_driver           = "server"
  proxy_mappings      = ["18080:adminer:8080"]
}

module "coder-login" {
  agent_id = coder_agent.main.id
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/coder-login/coder"
  version  = "1.1.0"
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

module "dotfiles" {
  source          = "git::https://github.com/emboldagency/coder-registry.git//modules/dotfiles?ref=v2026.03.11.0"
  count           = data.coder_workspace.me.start_count
  agent_id        = coder_agent.main.id
  user            = "embold"
  parameter_order = 10 # 3 parameters
  manual_update   = true
}

module "dynamic_services" {
  source              = "git::https://github.com/emboldagency/coder-registry.git//modules/dynamic-resources?ref=v2026.03.11.0"
  count               = data.coder_workspace.me.start_count
  agent_id            = coder_agent.main.id
  docker_network_name = docker_network.workspace[0].name
  resource_name_base  = local.resource_name_base
  parameter_order     = 30 # 34 parameters (pushed towards end)
}

module "home_setup" {
  source     = "git::https://github.com/emboldagency/coder-registry.git//modules/home-setup?ref=v2026.03.11.0"
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

module "mailpit" {
  source              = "git::https://github.com/emboldagency/coder-registry.git//modules/mailpit?ref=v2026.03.11.0"
  count               = data.coder_workspace.me.start_count
  agent_id            = coder_agent.main.id
  docker_network_name = docker_network.workspace[0].name
  resource_name_base  = local.resource_name_base
  proxy_mappings      = ["18025:mailpit:8025"]
}

module "ssh_setup" {
  source   = "git::https://github.com/emboldagency/coder-registry.git//modules/ssh-setup?ref=v2026.03.11.0"
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
  source          = "git::https://github.com/emboldagency/coder-registry.git//modules/timezone?ref=v2026.03.11.0"
  agent_id        = coder_agent.main.id
  parameter_order = 7 # 1 parameter
}

module "vault" {
  source     = "registry.coder.com/coder/vault-github/coder"
  version    = "1.1.2"
  count      = data.coder_workspace.me.start_count
  agent_id   = coder_agent.main.id
  vault_addr = "https://vault.embold.dev"
  # Pin: before bumping, verify binaries exist at https://releases.hashicorp.com/vault/<version>/.
  vault_cli_version = "2.0.0"
}

# DEPRECATED: Keep these parameters for backward compatibility with workspaces
# created while these version fields used their display labels as the stored
# parameter names. Existing workspaces keep their values under the old names.

# TODO: Remove this parameter once all workspaces have been upgraded.
data "coder_parameter" "dotfiles_url" {
  name         = "dotfiles URL"
  display_name = "Dotfiles URL (deprecated)"
  description  = "Legacy fallback for workspaces created before the dotfiles parameter key was corrected. Leave blank on new workspaces."
  icon         = "/icon/dotfiles.svg"
  type         = "string"
  default      = ""
  mutable      = true
  order        = 150
}

# TODO: Remove this parameter once all workspaces have been upgraded.
data "coder_parameter" "php_version_legacy" {
  name         = "PHP Version"
  display_name = "PHP Version (deprecated)"
  description  = "Legacy fallback for workspaces created before the PHP version parameter key was corrected. Leave blank on new workspaces."
  icon         = "/icon/php.svg"
  type         = "string"
  default      = ""
  mutable      = true
  order        = 151
}
# TODO: Remove this parameter once all workspaces have been upgraded.
data "coder_parameter" "mariadb_version_legacy" {
  name         = "MariaDB Version"
  display_name = "MariaDB Version (deprecated)"
  description  = "Legacy fallback for workspaces created before the MariaDB version parameter key was corrected. Leave blank on new workspaces."
  icon         = "https://api.embold.net/icons/?name=mariadb.svg"
  type         = "string"
  default      = ""
  mutable      = true
  order        = 152
}
# TODO: Remove this parameter once all workspaces have been upgraded.
data "coder_parameter" "ubuntu_version_legacy" {
  name         = "Ubuntu Version"
  display_name = "Ubuntu Version (deprecated)"
  description  = "Legacy fallback for workspaces created before the Ubuntu version parameter key was corrected. Leave blank on new workspaces."
  icon         = "/icon/ubuntu.svg"
  type         = "string"
  default      = ""
  mutable      = true
  order        = 153
}
