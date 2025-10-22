<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

[What's this section for?](https://keepachangelog.com/en/1.1.0/#effort)

<!-- ### Added -->
<!-- ### Changed -->
<!-- ### Deprecated -->
<!-- ### Removed -->
<!-- ### Fixed -->
<!-- ### Security -->

## [v1.6.3](https://github.com/emboldagency/docker-php/tree/v1.6.3) - 2025-10-22

## Changed

- Set `PULSAR_APP_NAME`.

## [v1.6.2](https://github.com/emboldagency/docker-php/tree/v1.6.2) - 2025-06-12

### Changed

- Use G for GiB

**Full Changelog**: https://github.com/emboldagency/docker-php/compare/v1.6.1...v1.6.2

## [v1.6.1](https://github.com/emboldagency/docker-php/tree/v1.6.1) - 2025-06-12

### Changed

- Update metadata to show database size in GB

**Full Changelog**: https://github.com/emboldagency/docker-php/compare/v1.6.0...v1.6.1

## [v1.6.0](https://github.com/emboldagency/docker-php/tree/v1.6.0) - 2025-06-12

### Added

- Browser and image processing dependencies.
- Metadata for workspace stats, template version, and links.

### Changed

- Refactor Apache environment variables handling.
- Use Coder GitHub action instead of custom steps.
- Update terraform providers.
- Copy ruby from ruby slim image instead of using ruby-build.

**Full Changelog**: https://github.com/emboldagency/docker-php/compare/v1.5.0...v1.6.0

## [v1.5.0](https://github.com/emboldagency/docker-php/tree/v1.5.0) - 2025-03-26

### Added

- Add TODO.md for tracking outstanding tasks and improvements, including more terraform modules to checkout.
- Improved error handling for Apache and PHP to provide better diagnostics.

### Changed

- Better error handling for Apache and PHP.
- Tie template version to Docker image tag.

**Full Changelog**: https://github.com/emboldagency/docker-php/compare/v1.4.0...v1.5.0

## [v1.4.0](https://github.com/emboldagency/docker-php/tree/v1.4.0) - 2024-12-04

### Added

- Github CLI token

**Full Changelog**: https://github.com/emboldagency/docker-php/compare/v1.3.2...v1.4.0

## [v1.3.2](https://github.com/emboldagency/docker-php/tree/v1.3.2) - 2024-12-04

### Changed

- Made pulsar magic template param mutable
- Changed pulsar magic template param color to embold blue

**Full Changelog**: https://github.com/emboldagency/docker-php/compare/v1.3.1...v1.3.2

## [v1.3.1](https://github.com/emboldagency/docker-php/tree/v1.3.1) - 2024-12-03

### Added

- Added PHP 8.4
- Added `mariadb_auto_upgrade` parameter and environment variable to facilitate upgrading the MariaDB version
- Added dotfiles coder param

### Changed

- Reintroduced option lists for certain Coder parameters where appropriate
- Upgraded terraform providers

### Fixed

- Corrected the reference for the Pulsar magic template parameter
- Resolved `Dockerfile FromAsCasing` warning
- Updated GitHub Action versions to address 'save-state' deprecations

**Full Changelog**: https://github.com/emboldagency/docker-php/compare/v1.3.0...v1.3.1

## [v1.3.0](https://github.com/emboldagency/docker-php/tree/v1.3.0) - 2024-11-27

### Added

- Pulsar magic template parameter

### Changed

- Capitalize references to Pulsar

**Full Changelog**: https://github.com/emboldagency/docker-php/compare/v1.2.1...v1.3.0

## [v1.2.1](https://github.com/emboldagency/docker-php/tree/v1.2.1) - 2024-08-08

Added manual workflow with job skipping; fixed deprecations; used locals for easier reference changes; fixed Coder template push job.

### Added

- Workflow can be run manually, with options to skip a job by name

### Changed

- Fix deprecations
- Use locals to help avoid repetition and make it easier to change references when Coder provider makes breaking changes

### Fixed

- Coder template push job

**Full Changelog**: https://github.com/emboldagency/docker-php/compare/v1.2.0...v1.2.1

## [v1.2.0](https://github.com/emboldagency/docker-php/tree/v1.2.0) - 2024-08-07

Added workflows for DockerHub and Coder publishing, php-bcmath for all PHP versions, and updated Coder provider and parameters.

### Added

- GitHub Actions workflows to push to DockerHub & publish the Coder template
- Install php-bcmath base for all PHP versions

### Changed

- Updated Coder provider
- Updated default parameter versions

**Full Changelog**: https://github.com/emboldagency/docker-php/compare/v1.1.0...v1.2.0

## [v1.1.0](https://github.com/emboldagency/docker-php/tree/v1.1.0) - 2024-04-08

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

## [v1.0.0] - 2023-11-17

Initial release
