# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2024-27-10

- Added explicit Swift 6 language version and mode support [@mobrien-ghost](https://github.com/CheekyGhost-Labs/OSLogClient/pull/22)
- Dropped Swift 5.7 support [@mobrien-ghost](https://github.com/CheekyGhost-Labs/OSLogClient/pull/22)
- Added Swift 6 -> 5.8 unit test actions [@mobrien-ghost](https://github.com/CheekyGhost-Labs/OSLogClient/pull/23)
- Added iOS, macOS, iPadOS, watchOS, tvOS, VisionPro integration tests [@mobrien-ghost](https://github.com/CheekyGhost-Labs/OSLogClient/pull/23)

## [1.2.0] - 2024-08-09

- Add frozen to LogLevel enum [@theoriginalbit #21](https://github.com/CheekyGhost-Labs/OSLogClient/pull/21)
- Fix LastProcessedStrategy extensions were not marked public [@theoriginalbit #20](https://github.com/CheekyGhost-Labs/OSLogClient/pull/20)

## [1.1.0] - 2024-24-08

- Fix crash caused by in-memory last processed handling being recursive [@theoriginalbit #17](https://github.com/CheekyGhost-Labs/OSLogClient/pull/19)

## [1.0.0] - 2024-15-06

- Enforcing structured concurrency by [@theoriginalbit #17](https://github.com/CheekyGhost-Labs/OSLogClient/pull/17)
- Enforcing structured concurrency by [@mobrien-ghost #16](https://github.com/CheekyGhost-Labs/OSLogClient/pull/16)

## [0.5.0] - 2024-28-05

- [Feature] Add Driver Registration Check to OSLogClient [@nickkohrn in #15](https://github.com/CheekyGhost-Labs/OSLogClient/pull/15)

## [0.4.0] - 2024-23-05

- Feature: Making LogDriver ID public by [@nickkohrn in #13](https://github.com/CheekyGhost-Labs/OSLogClient/pull/14)
- Feature: Adding check for whether driver is registered by [@nickkohrn in #13](https://github.com/CheekyGhost-Labs/OSLogClient/pull/13)


## [0.3.0] - 2024-26-04

### Changed

- Fixed Minor Typo in LogClient Method Documentation by [@nickkohrn in #10](https://github.com/CheekyGhost-Labs/OSLogClient/pull/10)
- Added force/immediate polling convenience helper

## [0.2.0] - 2024-05-01

### Changed

- [Fix privacy manifest not declaring UserDefaults usage](https://github.com/CheekyGhost-Labs/OSLogClient/pull/8)

## [0.2.0] - 2024-05-01

### Changed

- Added privacy manifest in resources bundle

## [0.1.2] - 2023-04-09

### Changed

- Removed unused timer property remaining from from initial concept.
- Updated README to fix typos and update method signatures


## [0.1.1] - 2023-30-08

### Changed

- [Improved polling query predicate logic](https://github.com/CheekyGhost-Labs/OSLogClient/pull/2)

## [0.1.0] - 2023-30-08

### Added

- Initial Release
