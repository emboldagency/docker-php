<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

[What's this section for?](https://keepachangelog.com/en/1.1.0/#effort)

### Changed

- Updated Coder Provider

## [v1.1](https://github.com/emboldagency/docker-php/tree/v1.1) - 2024-04-08

Added dynamic template options to customize the workspace.

### Added

- Added this changelog!
- New workspace parameters
  - _Pulsar App Name_: Workspace name can now be different than the Pulsar app name
  - _MariaDB Version_: Select which MariaDB image the database container uses.
  - _Ubuntu Version_: Choose a different version of our base image by the Ubuntu version number

### Changed

- Move images back to DockerHub, stop building the images during workspace startup.
- Changed web server user. Installing/updating plugins from the web interface should work now

### Fixed

- Docker Registry authentication now works using `TF_VAR` provided to the Coder stack
- Removed stats to avoid confusion since they show the host stats instead of the stats for the workspace
- Move gem home creation and gem install code into base
- Use system locale for apache

## [1.0] - 2023-11-17

Initial release
