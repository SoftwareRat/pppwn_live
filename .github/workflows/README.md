# GitHub Actions Workflows

This directory contains the CI/CD workflows for the PPPwn Live ISO project.

## Workflows Overview

### 1. `ci.yml` - Continuous Integration
**Triggers**: Push/PR to main/develop branches with changes to relevant paths
- Detects changes in different components (stage1, stage2, configs, etc.)
- Validates payload files and configurations
- Triggers builds only when necessary
- Provides detailed change summaries

### 2. `build.yml` - Build PPPwn Live ISO
**Triggers**: Called by other workflows or manual dispatch
- Fetches Buildroot from external repository
- Implements comprehensive caching strategy
- Builds the ISO with specified configuration
- Uploads build artifacts
- Supports matrix builds for different configurations

### 3. `release.yml` - Create Release
**Triggers**: Push to main branch or manual dispatch
- Builds ISO for release
- Generates version numbers automatically
- Creates GitHub releases with proper assets
- Includes checksums and build information
- Supports both automatic and manual versioning

### 4. `status-report.yml` - Build Status Report
**Triggers**: Completion of other workflows
- Reports build status and results
- Creates issues for build failures
- Closes issues when builds are fixed
- Updates build status information

### 5. `manual-build.yml` - Manual Build and Upload
**Triggers**: Manual dispatch only
- Allows manual builds with custom parameters
- Supports both artifact and release uploads
- Provides flexible configuration options

## Caching Strategy

The workflows implement a multi-level caching strategy:

1. **Buildroot Source Cache**: Caches the Buildroot repository clone
2. **Download Cache**: Caches downloaded packages and sources
3. **Build Artifact Cache**: Caches compiled objects and build outputs

## Build Triggers

Builds are automatically triggered when changes are made to:
- `br2-external/**` - Buildroot external tree
- `configs/**` - Build configurations
- `stage1/**` - PPPwn stage1 payloads
- `stage2/**` - PPPwn stage2 payloads
- `old_pppwnlive/**` - Legacy scripts and configurations
- `.github/workflows/**` - Workflow definitions

## Artifacts and Releases

### Artifacts
- Build artifacts are uploaded for every successful build
- Includes ISO file and build information
- Retained for 30 days (90 days for releases)

### Releases
- Automatic releases on main branch pushes
- Manual releases via workflow dispatch
- Includes ISO, checksums, and build information
- Proper semantic versioning support

## Usage

### Automatic Builds
Simply push changes to the main or develop branch. The CI system will:
1. Detect what changed
2. Validate the changes
3. Build if necessary
4. Create releases (main branch only)

### Manual Builds
Use the "Manual Build and Upload" workflow:
1. Go to Actions tab
2. Select "Manual Build and Upload"
3. Click "Run workflow"
4. Configure build parameters
5. Run the build

### Monitoring
- Check the Actions tab for build status
- Build failures automatically create issues
- Status reports provide detailed information
- Workflow summaries show change detection results

## Configuration

### Environment Variables
- `BUILDROOT_VERSION`: Buildroot version to use (default: 2025.05)
- `BUILDROOT_REPO`: Buildroot repository URL

### Secrets
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions
- No additional secrets required for basic functionality

## Troubleshooting

### Build Failures
1. Check the workflow logs for detailed error information
2. Verify Buildroot configuration is valid
3. Ensure all required files are present
4. Check for syntax errors in overlay scripts

### Cache Issues
If builds are failing due to cache corruption:
1. Go to Actions → Caches
2. Delete relevant caches
3. Re-run the workflow

### Release Issues
- Ensure proper permissions for creating releases
- Check that version numbers are unique
- Verify all required files are present