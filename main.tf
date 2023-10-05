# Note: this example demonstrates the use of
# dotfiles with Coder templates.

# The Docker aspect of the template only works
# with macOS/Linux amd64 systems. See the full
# Docker example for details

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

data "coder_provisioner" "me" {
}

provider "docker" {
  registry_auth {
    address  = "registry.hub.docker.com"
    username = "emboldcreative"
    password = "penholder-driller-strung-crablike"
  }
}

data "coder_workspace" "me" {
}

data "coder_parameter" "docker_image" {
  name         = "docker_image"
  display_name = "Docker image"
  description  = "The Docker image will be used to build your workspace."
  default      = "emboldcreative/docker-base-2204-v2:ubuntu-opt"
  icon         = "/icon/docker.png"
  type         = "string"
  mutable      = false
}

data "coder_parameter" "dotfiles_uri" {
  name         = "dotfiles_uri"
  display_name = "dotfiles URI"
  description  = <<-EOF
  Dotfiles repo URI (optional)

  see https://dotfiles.github.io
  EOF
  default      = ""
  type         = "string"
  mutable      = true
}

resource "coder_agent" "main" {
  arch                    = data.coder_provisioner.me.arch
  os                      = "linux"
  startup_script_timeout  = 180
  startup_script_behavior = "blocking"
  env = {
    "DOTFILES_URI" = data.coder_parameter.dotfiles_uri.value != "" ? data.coder_parameter.dotfiles_uri.value : null,
  }
  startup_script = <<-EOT
    set -e
    if [ -n "$DOTFILES_URI" ]; then
      echo "Installing dotfiles from $DOTFILES_URI"
      coder dotfiles -y "$DOTFILES_URI"
    fi
    /bin/bash /coder/configure
  EOT
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
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

resource "docker_volume" "mysql_data" {}

resource "docker_network" "workspace_network" {
  name = "workspace_network"
}

resource "docker_container" "mysql" {
  name         = "mysql"
  image        = "mariadb:10-jammy"
  restart      = "always"
  network_mode = "workspace_network"
  env = [
    "MYSQL_ROOT_PASSWORD=embold",
    "MYSQL_USER=embold",
    "MYSQL_PASSWORD=embold",
  ]
  volumes {
    container_path = "/var/lib/mysql"
    volume_name    = docker_volume.mysql_data.name
    read_only      = false
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = data.coder_parameter.docker_image.value
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
    container_path = "/home/coder/"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  network_mode = "workspace_network"
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

resource "coder_metadata" "container_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[0].id

  item {
    key   = "image"
    value = data.coder_parameter.docker_image.value
  }
}
