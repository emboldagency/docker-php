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

resource "coder_agent" "main" {
  arch                    = data.coder_provisioner.me.arch
  os                      = "linux"
  startup_script_timeout  = 180
  startup_script_behavior = "blocking"
  env = {
    "CODER_USERNAME" = data.coder_workspace.me.owner
    "CODER_WORKSPACE_PORT" = 80
    "CODER_WORKSPACE_NAME" = data.coder_workspace.me.name
    "APP" = data.coder_workspace.me.name
  }
  startup_script = <<-EOT
    set -e
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

resource "docker_volume" "db_volume" {
  name = "coder-${data.coder_workspace.me.id}-db"
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

resource "docker_network" "workspace_network" {
  name = "coder-${data.coder_workspace.me.id}-network"
  driver = "bridge"
}

resource "docker_container" "db" {
  name         = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-db"
  image        = "mariadb:10-jammy"
  restart      = "always"
  hostname     = "db"
  network_mode = docker_network.workspace_network.name
  env = [
    "MYSQL_ROOT_PASSWORD=embold",
    "MYSQL_USER=embold",
    "MYSQL_PASSWORD=embold",
  ]
  volumes {
    container_path = "/var/lib/mysql"
    volume_name    = docker_volume.db_volume.name
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
  network_mode = docker_network.workspace_network.name
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

resource "coder_app" "apache-app" {
  agent_id  = coder_agent.main.id
  slug      = "webapp"
  icon      = "https://upload.wikimedia.org/wikipedia/commons/7/7e/Apache_Feather_Logo.svg"
  url       = "http://localhost:80"
  subdomain = true
  share     = "public"

  healthcheck {
    url       = "http://localhost:80/"
    interval  = 10
    threshold = 30
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
