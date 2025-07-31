# Requirements Document

## Introduction

This feature involves creating a Buildroot-based Linux live ISO distribution named "pppwn_live" specifically designed for x64 PCs to automatically execute the PPPwn PS4 exploit. The system will integrate PPPwn components, provide hardware detection and network setup, offer user guidance during execution, and include automated CI/CD workflows for continuous builds.

## Requirements

### Requirement 1

**User Story:** As a PS4 exploit user, I want a bootable live ISO that automatically integrates PPPwn components, so that I can run the exploit without manual setup or compilation.

#### Acceptance Criteria

1. WHEN the system boots THEN it SHALL automatically include pre-built stage1 and stage2 folders from the PPPwn GitHub repository in the root filesystem
2. WHEN PPPwn components are integrated THEN the system SHALL track these folders within the repository for version control
3. WHEN PPPwn updates are available THEN the system SHALL automatically update the integrated components during the build process
4. WHEN the ISO is built THEN it SHALL target only x64 CPU architecture without ARM64 support

### Requirement 2

**User Story:** As a developer maintaining the system, I want to integrate existing scripts and configurations from old_pppwnlive, so that proven functionality is preserved and adapted for Buildroot.

#### Acceptance Criteria

1. WHEN building the system THEN it SHALL incorporate all scripts from the old_pppwnlive folder
2. WHEN building the system THEN it SHALL incorporate all configurations from the old_pppwnlive folder
3. WHEN building the system THEN it SHALL incorporate all user interface code from the old_pppwnlive folder
4. WHEN building the system THEN it SHALL incorporate all automation from the old_pppwnlive folder
5. WHEN integrating old components THEN the system SHALL adapt them for seamless Buildroot integration

### Requirement 3

**User Story:** As a PS4 exploit user, I want automatic hardware detection and network setup, so that the system can connect to PlayStation 4 consoles without manual configuration.

#### Acceptance Criteria

1. WHEN the system boots THEN it SHALL automatically detect available network hardware
2. WHEN network hardware is detected THEN the system SHALL configure network interfaces optimized for PS4 console detection
3. WHEN network is configured THEN the system SHALL automatically attempt to connect to PlayStation 4 consoles
4. WHEN PS4 console is detected THEN the system SHALL prepare for exploit execution

### Requirement 4

**User Story:** As a PS4 exploit user, I want clear status output and guidance during exploit execution, so that I understand what's happening and when the process completes.

#### Acceptance Criteria

1. WHEN exploit execution begins THEN the system SHALL display clear user guidance messages
2. WHEN exploit is running THEN the system SHALL provide real-time status output showing progress
3. WHEN exploit completes successfully THEN the system SHALL display success confirmation
4. WHEN exploit completes successfully THEN the system SHALL initiate a secure automatic shutdown sequence
5. WHEN errors occur THEN the system SHALL display helpful error messages and guidance

### Requirement 5

**User Story:** As a developer, I want the system to use external Buildroot source, so that the repository remains lightweight and uses the latest Buildroot version.

#### Acceptance Criteria

1. WHEN building the system THEN it SHALL obtain Buildroot source externally from https://github.com/buildroot/buildroot/tree/2025.05
2. WHEN building the system THEN it SHALL NOT include the entire Buildroot source tree inside the repository
3. WHEN building the system THEN it SHALL use the specified Buildroot branch (2025.05)
4. WHEN building the system THEN it SHALL configure Buildroot for a minimal live system

### Requirement 6

**User Story:** As a developer, I want continuous integration with GitHub Actions, so that builds are automated and artifacts are available when changes are made.

#### Acceptance Criteria

1. WHEN code is committed THEN the CI system SHALL clone or download Buildroot from the external repository
2. WHEN changes are made to stage1/ folder THEN the CI system SHALL trigger an automatic build
3. WHEN changes are made to stage2/ folder THEN the CI system SHALL trigger an automatic build
4. WHEN changes are made to old_pppwnlive/ folder THEN the CI system SHALL trigger an automatic build
5. WHEN changes are made to Buildroot configs THEN the CI system SHALL trigger an automatic build
6. WHEN build completes successfully THEN the CI system SHALL upload build artifacts
7. WHEN build completes successfully THEN the CI system SHALL create releases on commit

### Requirement 7

**User Story:** As a developer, I want proper Buildroot integration packages, so that PPPwn components are cleanly integrated into the build system.

#### Acceptance Criteria

1. WHEN building the system THEN it SHALL include Buildroot package files for stage1 integration
2. WHEN building the system THEN it SHALL include Buildroot package files for stage2 integration
3. WHEN building the system THEN it SHALL include Buildroot overlays for filesystem customization
4. WHEN building the system THEN it SHALL use a Buildroot defconfig optimized for the live system requirements
5. WHEN building the system THEN the defconfig SHALL target minimal system size while including necessary components

### Requirement 8

**User Story:** As a system administrator, I want the live ISO to be secure and self-contained, so that it can be safely used without persistent storage concerns.

#### Acceptance Criteria

1. WHEN the system runs THEN it SHALL operate entirely from memory without requiring persistent storage
2. WHEN the system shuts down THEN it SHALL securely clear any sensitive data from memory
3. WHEN the system operates THEN it SHALL include only necessary components to minimize attack surface
4. WHEN the system completes its task THEN it SHALL automatically shut down to prevent unauthorized access