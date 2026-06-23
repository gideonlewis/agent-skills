# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Example skill template for new skill development

### Changed

### Fixed

### Removed

---

## [1.0.0] - 2026-06-23

### Added
- Initial release with core infrastructure
  - `install.sh` - One-command installation
  - `sync.sh` - Update mechanism for multiple machines
  - `status.sh` - Check installation status
- Example skill template
- Comprehensive documentation
  - SETUP.md - Installation guide
  - CREATING_SKILLS.md - Skill development guide
- MIT License

---

## How to Update This File

When you add a new skill or make changes, update this file:

```markdown
## [1.1.0] - 2026-06-25

### Added
- New skill: my-awesome-skill
- Support for environment variable configuration

### Fixed
- Symlink creation on Windows
```

### Version Format
- **[X.Y.Z]** - Major.Minor.Patch
- **Major** - Breaking changes
- **Minor** - New features (backwards compatible)
- **Patch** - Bug fixes

### Sections
- **Added** - New features or skills
- **Changed** - Updates to existing skills
- **Fixed** - Bug fixes
- **Removed** - Removed skills or features
- **Deprecated** - Features to be removed soon
