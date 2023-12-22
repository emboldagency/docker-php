terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.12.1"
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
}

data "coder_provisioner" "me" {
}

data "coder_workspace" "me" {
}

locals {
  dev_url    = "https://webapp--main--${data.coder_workspace.me.name}--${data.coder_workspace.me.owner}.embold.app"
  code_root = "/home/embold/code/${data.coder_workspace.me.name}"
}

data "coder_parameter" "php_version" {
  name        = "PHP Version"
  description = "Which version of PHP should we build?"
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

  option {
    name  = "7.3"
    value = "7.3"
  }
}

resource "coder_agent" "main" {
  arch                    = data.coder_provisioner.me.arch
  os                      = "linux"
  startup_script_timeout  = 180
  startup_script_behavior = "blocking"
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Disk Usage"
    key          = "2_disk_usage"
    script       = "df -h | awk '$6 ~ /^\\/$/ { print $5 }'"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Load Average"
    key          = "3_load_average"
    script       = <<EOT
            awk '{print $1,$2,$3}' /proc/loadavg
        EOT
    interval     = 10
    timeout      = 1
  }
  env = {
    "APP"                  = data.coder_workspace.me.name
    "CODER_USERNAME"       = data.coder_workspace.me.owner
    "CODER_WORKSPACE_NAME" = data.coder_workspace.me.name
    "CODER_WORKSPACE_PORT" = 443
    "DEVURL"               = local.dev_url
    "GIT_AUTHOR_EMAIL"     = data.coder_workspace.me.owner_email
    "GIT_AUTHOR_NAME"      = data.coder_workspace.me.owner
    "GIT_COMMITTER_EMAIL"  = data.coder_workspace.me.owner_email
    "GIT_COMMITTER_NAME"   = data.coder_workspace.me.owner
    "MYSQL_HOST"           = "mysql"
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
  image        = "mariadb:10.4"
  hostname     = "mysql"
  network_mode = docker_network.workspace[count.index].name
  env = [
    "MYSQL_ROOT_PASSWORD=embold",
    "MYSQL_DATABASE=${replace(data.coder_workspace.me.name, "-", "_")}",
    "MYSQL_USER=embold",
    "MYSQL_PASSWORD=embold",
  ]
  volumes {
    container_path = "/var/lib/mysql"
    volume_name    = docker_volume.mysql_volume.name
    read_only      = false
  }
}

resource "docker_image" "php" {
  name         = "registry.embold.app/php:${data.coder_parameter.php_version.value}-ubuntu22.04"
  keep_locally = true
  build {
    context = "./build"
    tag     = ["registry.embold.app/php:${data.coder_parameter.php_version.value}-ubuntu22.04"]
    build_args = {
      PHP_VERSION : data.coder_parameter.php_version.value
    }
    target = "final"
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "build/**/*") : filesha1(f)]))
  }
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
  env        = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
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
    value = docker_image.php.name
  }
  item {
    key   = "dev_url"
    value = local.dev_url
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
  folder       = local.code_root
  extensions   = []
  settings = {
    "workbench.colorTheme" : "Default Dark Modern"
  }
}

module "jetbrains_gateway" {
  source         = "https://registry.coder.com/modules/jetbrains-gateway"
  agent_id       = coder_agent.main.id
  agent_name     = data.coder_workspace.me.name
  folder         = local.code_root
  jetbrains_ides = ["PS"]
  default        = "PS"
}
