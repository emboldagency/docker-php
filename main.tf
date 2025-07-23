# --- PROVIDERS ---
terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 2.8.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6.1"
    }
  }
}

provider "coder" {}
provider "docker" {
  registry_auth {
    address  = "registry-1.docker.io"
    username = "emboldcreative"
    password = var.DOCKER_REGISTRY_PASS
  }
}

# --- VARIABLES ---
variable "DOCKER_REGISTRY_PASS" {
  sensitive = true
}

# --- DATA BLOCKS ---
data "coder_external_auth" "github" { id = "github" }
data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

data "coder_parameter" "db_type" {
  name        = "Database Type"
  description = "Choose the database type for your workspace."
  type        = "string"
  default     = "mariadb"
  mutable     = true
  option {
    name  = "MariaDB"
    value = "mariadb"
  }
  option {
    name  = "Postgres"
    value = "postgres"
  }
}

# Composer Token parameter
data "coder_parameter" "composer_token" {
  name        = "Composer Token"
  description = "GitHub or Composer API token for private Composer packages."
  type        = "string"
  default     = ""
  mutable     = true
}

# data "coder_parameter" "dotfiles_url" {
#   name        = "dotfiles URL"
#   description = "GitHub repository with dotfiles"
#   type        = "string"
#   mutable     = true
# }

# This is a placeholder for the dotfiles URL parameter provided by the dotfiles module.
# We can't supply the param, but it must exist or the template will fail.

# variable "dotfiles_uri" {
#   type    = string
#   default = null
# }

# data "coder_parameter" "dotfiles_uri" {
#   count        = var.dotfiles_uri == null ? 1 : 0
#   type         = "string"
#   name         = "dotfiles_uri"
#   display_name = "Dotfiles URL"
#   description  = "Enter a URL for a [dotfiles repository](https://dotfiles.github.io) to personalize your workspace"
#   mutable      = true
#   icon         = "/icon/dotfiles.svg"
# }

data "coder_parameter" "git_clone_url" {
  name        = "Git Clone URL"
  description = "The HTTPS version of the Git Repo to clone."
  type        = "string"
  default     = ""
  mutable     = false
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

# TODO: Conditionally show parameter based on db_type
data "coder_parameter" "mariadb_version" {
  name        = "MariaDB Version"
  description = "What version of MariaDB? Must match an official mariadb image tag on DockerHub"
  icon        = "/icon/database.svg"
  type        = "string"
  default     = "10.11"
  mutable     = true
}
# TODO: Conditionally show parameter based on db_type
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
data "coder_parameter" "vscode_web_theme" {
  name        = "VS Code Web Theme"
  description = "Which theme do you prefer for VS Code Web?"
  icon        = "/icon/code.svg"
  type        = "string"
  default     = "Default Dark Modern"
  mutable     = true
}

# --- LOCALS ---
locals {
  app                   = lower(try(length(local.pulsar_app_name), 0) > 0 ? local.pulsar_app_name : local.workspace_name)
  db_name               = replace(local.app, "-", "_")
  dev_url               = "https://webapp--main--${local.workspace_name}--${local.user_username}.embold.dev"
  # dotfiles_url          = module.dotfiles[coder_workspace.me[count.index]].dotfiles_uri
  github_token          = data.coder_external_auth.github.access_token
  mariadb_version       = coalesce(data.coder_parameter.mariadb_version.value, "10.11")
  mariadb_auto_upgrade  = data.coder_parameter.mariadb_auto_upgrade.value ? "1" : "0"
  php_version           = data.coder_parameter.php_version.value
  postgres_version      = coalesce(data.coder_parameter.postgres_version.value, "16")
  pulsar_app_name       = data.coder_parameter.pulsar_app_name.value
  pulsar_magic_template = data.coder_parameter.pulsar_magic_template.value
  resource_name_prefix  = "coder-${local.user_username}-${local.workspace_name}"
  template_version      = "1.7.0"
  ubuntu_version        = data.coder_parameter.ubuntu_version.value
  db_type               = data.coder_parameter.db_type.value
  db_key                = local.db_type == "mariadb" ? "MariaDB" : "Postgres"
  db_version            = local.db_type == "mariadb" ? local.mariadb_version : local.postgres_version
  db_hostname           = local.db_type == "mariadb" ? "mysql" : "postgres"
  user_email            = data.coder_workspace_owner.me.email
  user_full_name        = coalesce(data.coder_workspace_owner.me.full_name, local.user_username)
  user_id               = data.coder_workspace_owner.me.id
  user_username         = lower(data.coder_workspace_owner.me.name)
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = lower(data.coder_workspace.me.name)
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
    # DOTFILES_URL          = try(data.coder_paramegitter.dotfiles_uri.value, null)
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
  # metadata {
  #   display_name = "Home Volume Size"
  #   key          = "home_volume_size"
  #   script       = "du -BG --apparent-size /home/embold | tail -1 | awk '{print $1}'"
  #   interval     = 300
  #   timeout      = 30
  #   order        = 3
  # }
  startup_script = <<-EOT
    echo "Coder main workspace agent started."
    exit 0
  EOT
}

resource "coder_script" "ssh_github_keys" {
  agent_id     = coder_agent.main.id
  display_name = "SSH & GitHub Keys"
  run_on_start = true
  icon         = "icons/git.svg"
  script       = <<-EOT
    set -ex
    if [ ! -d "/home/embold/.ssh" ]; then
      rsync -a --ignore-existing /coder/conf/.ssh /home/embold
      touch ~/.ssh/known_hosts
      # Use static GitHub SSH host keys file to avoid API rate limits
      curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer <YOUR-TOKEN>" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/meta | jq -r '.ssh_keys | .[]' | sed -e 's/^/github.com /' >>~/.ssh/known_hosts      ssh-keyscan -t rsa embold.net >>/home/embold/.ssh/known_hosts
      mkdir -p /home/embold/.config/coder-api
      curl --request GET \
        --url "${data.coder_workspace.me.access_url}/api/v2/workspaceagents/me/gitsshkey" \
        --header "Coder-Session-Token: $CODER_AGENT_TOKEN" \
        -o /home/embold/.config/coder-api/gitsshkey.json &&
        jq -r '.public_key' /home/embold/.config/coder-api/gitsshkey.json |
        tr -d "\n" >/home/embold/.ssh/coder.pub &&
        echo -n " coder:$CODER_USERNAME@embold.dev" >>/home/embold/.ssh/coder.pub &&
        jq -r '.private_key' /home/embold/.config/coder-api/gitsshkey.json \
            >/home/embold/.ssh/coder
      sudo chmod 0700 /home/embold/.ssh
      sudo chmod 600 /home/embold/.ssh/*
      sudo chmod 600 /home/embold/.config/coder-api/gitsshkey.json
      git config --global gpg.format ssh
      git config --global commit.gpgsign true
      git config --global user.signingkey ~/.ssh/coder
    fi
    exit 0
  EOT
}

# resource "coder_script" "dotfiles" {
#   agent_id     = coder_agent.main.id
#   display_name = "Dotfiles Installation"
#   run_on_start = true
#   script       = <<-EOT
#     set -ex
#     echo "Installing dotfiles from ${local.dotfiles_url}"
#     coder dotfiles -y "${local.dotfiles_url}"
#   EOT
# }

resource "coder_script" "homebrew" {
  agent_id     = coder_agent.main.id
  display_name = "Homebrew (Linuxbrew)"
  run_on_start = true
  icon         = "https://brew.sh/assets/img/homebrew-256x256.png"
  script       = <<-EOT
    set -ex
    # Ensure Homebrew is available in this shell
    if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
      eval "$('/home/linuxbrew/.linuxbrew/bin/brew' shellenv)"
    elif command -v brew >/dev/null 2>&1; then
      eval "$($(command -v brew) shellenv)"
    else
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$('/home/linuxbrew/.linuxbrew/bin/brew' shellenv)"
      else
        echo "Homebrew install failed or brew not found. Exiting."
        exit 1
      fi
    fi
    # Add brew to PATH for current and future sessions (.profile)
    if ! grep -q 'brew shellenv' /home/embold/.profile 2>/dev/null; then
      echo 'eval "$($(brew --prefix)/bin/brew shellenv)"' >> /home/embold/.profile
    fi
    # Add brew to PATH for current and future zsh sessions (.zshrc)
    if ! grep -q 'brew shellenv' /home/embold/.zshrc 2>/dev/null; then
      echo 'eval "$($(brew --prefix)/bin/brew shellenv)"' >> /home/embold/.zshrc
    fi
    # Install required packages if not already installed
    for pkg in gcc composer mailpit micro zoxide; do
      if ! brew list "$pkg" >/dev/null 2>&1; then
        brew install "$pkg"
      else
        echo "$pkg already installed, skipping."
      fi
    done
    # Start mailpit in background if not running
    if command -v mailpit >/dev/null 2>&1; then
      PID=$(pgrep -f 'mailpit' || true)
      if [ -n "$PID" ]; then
        echo "Killing stale mailpit process: $PID"
        kill -9 $PID || true
        sleep 1
      fi
      echo "Starting mailpit..."
      nohup mailpit > /tmp/mailpit.log 2>&1 &
      sleep 2
      if pgrep -f 'mailpit' >/dev/null 2>&1; then
        echo "Mailpit is running at http://localhost:8025"
      else
        echo "Mailpit failed to start. Check /tmp/mailpit.log for details."
      fi
    else
      echo "mailpit not found in PATH."
    fi
    echo "Homebrew and required packages installed."
    exit 0
  EOT
}

module "dotfiles" {
  agent_id             = coder_agent.main.id
  count                = data.coder_workspace.me.start_count
  source               = "registry.coder.com/coder/dotfiles/coder"
  version              = "1.2.1"
  default_dotfiles_uri = "git@github.com:emboldagency/dotfiles.git"
  # user = "embold"
}

# Browsersync
resource "coder_script" "browsersync" {
  agent_id     = coder_agent.main.id
  display_name = "Browsersync"
  icon         = "https://browsersync.io/img/icons/icons.svg#svg-logo"
  run_on_start = true
  script       = <<-EOT
    set -ex
    mkdir -p /home/embold/.local/code
    if [ ! -d "/home/embold/.local/code/browsersync" ]; then
      git clone git@github.com:emboldagency/backend-browsersync.git /home/embold/.local/code/browsersync
    fi
    exit 0
  EOT
}

# Zoxide
# resource "coder_script" "zoxide" {
#   agent_id     = coder_agent.main.id
#   display_name = "Zoxide"
#   run_on_start = true
#   script       = <<-EOT
#     set -ex
#     eval "$($(brew --prefix)/bin/brew shellenv)"
#     if brew list zoxide >/dev/null 2>&1; then
#       echo "zoxide already installed, skipping."
#       exit 0
#     fi
#     brew install zoxide
#     exit 0
#   EOT
# }

# Micro Editor Install
# resource "coder_script" "micro" {
#   agent_id     = coder_agent.main.id
#   display_name = "Micro Editor"
#   run_on_start = true
#   icon         = "https://micro-editor.github.io/micro_files/micro-logo-mark.svg"
#   script       = <<-EOT
#     set -ex
#     eval "$($(brew --prefix)/bin/brew shellenv)"
#     if brew list micro >/dev/null 2>&1; then
#       echo "micro already installed, skipping."
#       exit 0
#     fi
#     brew install micro
#     exit 0
#   EOT
# }

# resource "coder_script" "embold_binary" {
#   agent_id     = coder_agent.main.id
#   display_name = "Embold Binary/Config"
#   run_on_start = true
#   script       = <<-EOT
#     set -ex
#     embold=H4sIAAAAAAAAA52SMQ7DMAhFd5+CqWPv0itkyFDJErbk+h+/wcTGtM7Q/iUKmCf4QLRWNW0XT5YKV4k660cggJtFdmAAifgPIJCBJ0Q5vwQPA6YBtH6TpUXJZYIAlHkiZ6BN/Piw4BM4qAGdpMzO8x5G61TLvzvs32DNdTDy5GF/bsuZ/j1QY6F11hZjzAXQVy2B6uIBlGCzjs6RCx3MeeJUnfWjWpMuw+IhZQWRjb27iuiXmegSeGz5PvZb5AQLUcl7G2XjGNmfIEde3V7lWLfzZXgDYVxqC3sDAAA=
#     base64 -d <<<"$embold" | gunzip
#     echo
#     exit 0
#   EOT
# }

# resource "coder_script" "composer" {
#   agent_id     = coder_agent.main.id
#   display_name = "Composer"
#   run_on_start = true
#   icon         = "https://getcomposer.org/favicon.ico"
#   script       = <<-EOT
#     set -ex
#     eval "$($(brew --prefix)/bin/brew shellenv)"
#     if brew list composer >/dev/null 2>&1; then
#       echo "composer already installed, skipping."
#       exit 0
#     fi
#     brew install composer
#     exit 0
#   EOT
# }

# resource "coder_agent" "db" {
#   arch = data.coder_provisioner.me.arch
#   os   = "linux"
#   startup_script_behavior = "blocking"
#   # env = local.db_type == "mariadb" ? {
#   #   DB_TYPE              = local.db_type
#   #   DB_HOST              = local.db_hostname
#   #   DB_NAME              = local.db_name
#   #   DB_USER              = "embold"
#   #   DB_PASSWORD          = "embold"
#   #   MARIADB_VERSION      = local.db_version
#   #   MARIADB_AUTO_UPGRADE = local.mariadb_auto_upgrade
#   #   } : {
#   #   DB_TYPE          = local.db_type
#   #   DB_HOST          = local.db_hostname
#   #   DB_NAME          = local.db_name
#   #   DB_USER          = "embold"
#   #   DB_PASSWORD      = "embold"
#   #   POSTGRES_VERSION = local.db_version
#   # }
#   # startup_script = <<-EOT
#   #   set -ex
#   #   if [ "${local.db_type}" = "mariadb" ]; then
#   #     echo "Starting MariaDB..."
#   #     docker run --name mysql -e MYSQL_ROOT_PASSWORD=embold -e MYSQL_DATABASE=${local.db_name} -e MYSQL_USER=embold -e MYSQL_PASSWORD=embold -d mariadb:${local.mariadb_version}
#   #   else
#   #     echo "Starting Postgres..."
#   #     docker run --name postgres -e POSTGRES_DB=${local.db_name} -e POSTGRES_USER=embold -e POSTGRES_PASSWORD=embold -d postgres:${local.postgres_version}
#   #   fi
#   #   exit 0
#   # EOT
#   startup_script = <<-EOT
#     set -ex

#     echo "Coder database agent started."
#     exit 0
#   EOT
#   metadata {
#     display_name = "CPU Usage"
#     key          = "cpu"
#     script       = "coder stat cpu"
#     interval     = 30
#     timeout      = 1
#     order        = 1
#   }
#   metadata {
#     display_name = "Memory Usage"
#     key          = "mem"
#     script       = "coder stat mem --prefix 'Gi' | sed 's/ //;s/iB//'"
#     interval     = 30
#     timeout      = 1
#     order        = 2
#   }
#   metadata {
#     display_name = "Database Size"
#     key          = "db_volume_size"
#     script       = local.db_type == "mariadb" ? "mariadb -N -e \"SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) FROM information_schema.tables;\" 2>/dev/null | awk '{print $1 \"G\"}'" : "psql -U embold -d ${local.db_name} -c \"SELECT pg_size_pretty(pg_database_size('${local.db_name}'));\" -t | awk '{print $1}'"
#     interval     = 300
#     timeout      = 30
#     order        = 1
#   }
#   # metadata {
#   #   display_name = "Database Volume Size"
#   #   key          = "db_actual_volume_size"
#   #   script       = local.db_type == "mariadb" ? "du -BG /var/lib/mysql | tail -1 | awk '{print $1}'" : "du -BG /var/lib/postgresql/data | tail -1 | awk '{print $1}'"
#   #   interval     = 300
#   #   timeout      = 30
#   #   order        = 2
#   # }
#   metadata {
#     display_name = "Database Version"
#     key          = "db_version"
#     script       = local.db_type == "mariadb" ? "mariadb --version | awk '{print $3}'" : "psql --version | awk '{print $3}'"
#     interval     = 300
#     timeout      = 10
#     order        = 2
#   }
# }

# resource "coder_agent" "redis" {
#   arch = data.coder_provisioner.me.arch
#   os   = "linux"
#   env = {
#     REDIS_VERSION   = "latest"
#     REDIS_DATA_PATH = "/data"
#   }
#   metadata {
#     display_name = "Redis Volume Size"
#     key          = "redis_actual_volume_size"
#     script       = "du -BG /data | tail -1 | awk '{print $1}'"
#     interval     = 300
#     timeout      = 30
#     order        = 2
#   }
#   metadata {
#     display_name = "Redis Info"
#     key          = "redis_info"
#     script       = "redis-cli info memory | grep 'used_memory:' | awk -F: '{print $2}'"
#     interval     = 300
#     timeout      = 10
#     order        = 2
#   }
# }

# resource "coder_agent" "adminer" {
#   arch                    = data.coder_provisioner.me.arch
#   os                      = "linux"
#   startup_script_behavior = "blocking"
#   startup_script          = <<-EOF
#     set -e
#     apk --no-cache add curl
#   EOF
# }

# resource "coder_agent" "mailpit" {
#   arch = data.coder_provisioner.me.arch
#   os   = "linux"
# startup_script_behavior = "blocking"
# startup_script          = <<-EOF
#   set -e
#   apt-get update && \
#   apt-get install curl -y && \
#   rm -rf /var/lib/apt/lists/*
# EOF
# }

resource "docker_volume" "home_volume" {
  name = "${local.resource_name_prefix}-${local.workspace_id}-home"
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
    label = "coder.username"
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
    label = "coder.workspace_name_at_creation"
    value = local.workspace_name
  }
}

# Persistent MySQL volume
resource "docker_volume" "mysql_volume" {
  name = "${local.resource_name_prefix}-${local.workspace_id}-mysql"
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

# Persistent Postgres volume
resource "docker_volume" "postgres_volume" {
  name = "${local.resource_name_prefix}-postgres"
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

# Persistent Homebrew (Linuxbrew) volume
resource "docker_volume" "linuxbrew_volume" {
  name = "${local.resource_name_prefix}-${local.workspace_id}-linuxbrew"
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
  name  = "${local.resource_name_prefix}-network"
  count = data.coder_workspace.me.start_count
}

# resource "docker_image" "mariadb" {
#   name         = "mariadb"
#   keep_locally = true
#   build {
#     context = "./build/mariadb"
#     build_args = {
#       MARIADB_VERSION : local.mariadb_version
#     }
#     tag = ["mariadb:${local.mariadb_version}-custom"]
#   }
# }

resource "docker_container" "mysql" {
  count = local.db_type == "mariadb" ? data.coder_workspace.me.start_count : 0
  name  = "${local.resource_name_prefix}-mysql"
  image = "mariadb:${local.mariadb_version}"
  # image        = docker_image.mariadb.name
  hostname     = "mysql"
  network_mode = docker_network.workspace[count.index].name
  env = [
    # "CODER_AGENT_TOKEN=${coder_agent.db.token}",
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "MYSQL_ROOT_PASSWORD=embold",
    "MYSQL_DATABASE=${local.db_name}",
    "MYSQL_USER=embold",
    "MYSQL_PASSWORD=embold",
    "MARIADB_AUTO_UPGRADE=${local.mariadb_auto_upgrade}",
  ]
  volumes {
    container_path = "/var/lib/mysql"
    volume_name    = docker_volume.mysql_volume.name
    read_only      = false
  }
  healthcheck {
    test = [
      "CMD", "healthcheck.sh", "--su-mysql", "--connect"
    ]
    interval     = "30s"
    timeout      = "10s"
    retries      = 5
    start_period = "20s"
  }
}

# TODO: Conditionally show parameter based on db_type
data "coder_parameter" "postgres_version" {
  name        = "Postgres Version"
  description = "What version of Postgres? Must match an official postgres image tag on DockerHub"
  icon        = "/icon/database.svg"
  type        = "string"
  default     = "16"
  mutable     = true
  option {
    name  = "16"
    value = "16"
  }
  option {
    name  = "15"
    value = "15"
  }
  option {
    name  = "14"
    value = "14"
  }
}

# resource "docker_image" "postgres" {
#   name         = "emboldcreative/postgres"
#   keep_locally = false
#   build {
#     context = "./build/postgres"
#     build_args = {
#       POSTGRES_VERSION : local.postgres_version
#     }
#     tag = ["postgres:${local.postgres_version}-custom"]
#   }
# }

resource "docker_container" "postgres" {
  count = local.db_type == "postgres" ? data.coder_workspace.me.start_count : 0
  name  = "${local.resource_name_prefix}-postgres"
  image = "postgres:${data.coder_parameter.postgres_version.value}"
  # image        = docker_image.postgres.name
  hostname     = local.db_hostname
  network_mode = docker_network.workspace[count.index].name
  env = [
    # "CODER_AGENT_TOKEN=${coder_agent.db.token}",
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "POSTGRES_DB=${local.db_name}",
    "POSTGRES_USER=embold",
    "POSTGRES_PASSWORD=embold",
  ]
  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = docker_volume.postgres_volume.name
    read_only      = false
  }
  healthcheck {
    test = [
      "CMD-SHELL", "pg_isready -q -d ${local.db_name} -U embold"
    ]
    interval = "30s"
    timeout  = "5s"
    retries  = 3
  }
}

data "docker_registry_image" "php" {
  name = "emboldcreative/php:${local.php_version}-ubuntu${local.ubuntu_version}-release${local.template_version}"
}

resource "docker_image" "php" {
  name          = data.docker_registry_image.php.name
  pull_triggers = [data.docker_registry_image.php.sha256_digest]
  keep_locally  = true
}

resource "docker_container" "workspace" {
  count      = data.coder_workspace.me.start_count
  image      = docker_image.php.name
  name       = local.resource_name_prefix
  hostname   = local.workspace_name
  entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  env = local.db_type == "mariadb" ? compact([
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "GITHUB_TOKEN=${local.github_token}",
    "MYSQL_HOST=${local.db_hostname}",
    "MYSQL_DATABASE=${local.db_name}",
    "MYSQL_USER=embold",
    "MYSQL_PASSWORD=embold"
    ]) : compact([
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "GITHUB_TOKEN=${local.github_token}",
    "PGHOST=${local.db_hostname}",
    "PGDATABASE=${local.db_name}",
    "PGUSER=embold",
    "PGPASSWORD=embold"
  ])
  volumes {
    container_path = "/home/embold"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  volumes {
    container_path = "/home/linuxbrew"
    volume_name    = docker_volume.linuxbrew_volume.name
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
  order        = 1
  # healthcheck {
  #   url       = "http://localhost:443"
  #   interval  = 5
  #   threshold = 6
  # }
}

# resource "docker_image" "mailpit" {
#   # name = "axllent/mailpit:latest"
#   name = "emboldcreative/mailpit:latest"
#   build {
#     context = "./build/mailpit"
#     tag     = ["mailpit:latest"]
#   }
# }

# resource "docker_container" "mailpit" {
#   count        = data.coder_workspace.me.start_count
#   name         = "mailpit"
#   image        = docker_image.mailpit.name
#   network_mode = docker_network.workspace[count.index].name
#   env = [
#     "CODER_AGENT_TOKEN=${coder_agent.mailpit.token}",
#   ]
# }

resource "coder_app" "mailpit" {
  agent_id     = coder_agent.main.id
  slug         = "mailpit"
  display_name = "Mailpit"
  url          = "http://localhost:8025"
  share        = "owner"
  subdomain    = true
  icon         = "https://mailpit.axllent.org/images/mailpit.svg"
  healthcheck {
    url       = "http://localhost:8025"
    interval  = 5
    threshold = 6
  }
  # order        = var.order
}

# resource "coder_script" "mailpit" {
#   agent_id     = coder_agent.main.id
#   display_name = "Mailpit"
#   icon         = "https://mailpit.axllent.org/images/mailpit.svg"
#   run_on_start = true
#   script       = <<-EOT
#     set -ex
#     eval "$($(brew --prefix)/bin/brew shellenv)"
#     if brew list mailpit >/dev/null 2>&1; then
#       echo "mailpit already installed, skipping."
#       exit 0
#     fi
#     brew install mailpit
#     nohup mailpit > /tmp/mailpit.log 2>&1 &
#     echo "Mailpit is running at http://localhost:8025"
#     exit 0
#   EOT
# }

resource "coder_script" "adminer" {
  agent_id     = coder_agent.main.id
  display_name = "Adminer"
  icon         = "http://www.adminer.org/favicon.ico"
  run_on_start = true
  script       = <<-EOT
    set -e
    echo "Installing Adminer..." && \
    mkdir -p /home/embold/.local/tmp/adminer/adminer-plugins && \
    curl -L -o /home/embold/.local/tmp/adminer/index.php https://www.adminer.org/latest.php && \
    curl -L -o /home/embold/.local/tmp/adminer/plugin.php https://www.adminer.org/plugin.php && \
    touch /home/embold/.local/tmp/adminer/adminer.php && \
    git clone https://github.com/arxeiss/Adminer-FillLoginForm /home/embold/.local/tmp/arxeiss/Adminer-FillLoginForm && \
    cp /home/embold/.local/tmp/arxeiss/Adminer-FillLoginForm/fill-login-form.php /home/embold/.local/tmp/adminer/adminer-plugins/fill-login-form.php && \
    echo "<?php" > /home/embold/.local/tmp/adminer/adminer.php
    echo "error_reporting(E_ALL);" >> /home/embold/.local/tmp/adminer/adminer.php
    echo "ini_set('display_errors', 1);" >> /home/embold/.local/tmp/adminer/adminer.php
    echo "require_once 'plugin.php';" >> /home/embold/.local/tmp/adminer/adminer.php
    echo "require_once 'adminer-plugins/fill-login-form.php';" >> /home/embold/.local/tmp/adminer/adminer.php
    echo "$plugins = [new FillLoginForm('pgsql', '${local.db_hostname}','embold','embold','${local.db_name}')];" >> /home/embold/.local/tmp/adminer/adminer.php
    echo "adminer_plugin($plugins);" >> /home/embold/.local/tmp/adminer/adminer.php
    echo "?>" >> /home/embold/.local/tmp/adminer/adminer.php
    chown -R embold:embold /home/embold/.local/tmp/adminer && \
    chmod -R 755 /home/embold/.local/tmp/adminer && \
    echo "Adminer installed successfully." && \
    echo "Starting Adminer..." && \
    cd /home/embold/.local/tmp/adminer && \
    nohup php -S localhost:8080 > /home/embold/.local/tmp/adminer/php-server.log 2>&1 &
    echo "Adminer is running at http://localhost:8080"
    exit 0
  EOT
}

resource "coder_app" "adminer" {
  agent_id     = coder_agent.main.id
  slug         = "adminer"
  display_name = "Adminer"
  url          = "http://localhost:8080"
  icon         = "http://www.adminer.org/favicon.ico"
  share        = "owner"
  order        = 2
  healthcheck {
    url       = "http://localhost:8080"
    interval  = 5
    threshold = 6
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
    key   = local.db_key
    value = local.db_version
  }
  item {
    key   = "Ubuntu"
    value = local.ubuntu_version
  }
  item {
    key   = "Image"
    value = basename(docker_image.php.name)
  }
  item {
    key   = "Template"
    value = local.template_version
  }
}

module "code-server" {
  display_name = "VS Code Web"
  source       = "registry.coder.com/coder/code-server/coder"
  agent_id     = coder_agent.main.id
  folder       = "/home/embold/code/${local.app}"
  extensions   = []
  settings = {
    "workbench.colorTheme" : data.coder_parameter.vscode_web_theme.value
  }
}

module "git-clone" {
  count       = data.coder_workspace.me.start_count
  source      = "registry.coder.com/coder/git-clone/coder"
  version     = "1.1.0"
  agent_id    = coder_agent.main.id
  url         = data.coder_parameter.git_clone_url.value
  folder_name = local.app
  base_dir    = "/home/embold/code"
}

module "git-config" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/git-config/coder"
  version  = "1.0.15"
  agent_id = coder_agent.main.id
}

module "git-commit-signing" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/git-commit-signing/coder"
  version  = "1.0.11"
  agent_id = coder_agent.main.id
}

module "jetbrains" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/jetbrains/coder"
  version  = "1.0.0"
  agent_id = coder_agent.main.id
  folder   = "/home/embold/code/${local.app}"
  default  = ["PS"]
}

# module "vault" {
#   count      = data.coder_workspace.me.start_count
#   source     = "registry.coder.com/coder/vault-github/coder"
#   version    = "1.0.7"
#   agent_id   = coder_agent.example.id
#   vault_addr = "https://vault.example.com"
# }
