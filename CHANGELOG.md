# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.1] - 2026-01-18
### Added
- Export CustomCSS classes for easier access to custom CSS functionality

## [1.2.0] - 2026-01-18
### Added
- Mention plugin with @-trigger detection and user picker
- SmartBlockquotePlugin class-based structure
- MentionUser model for user mentions
### Changed
- Renamed RichEditor classes to MB prefix (MBRichEditorController, MBRichEditor)
- Consolidated mention logic into MentionPlugin class
- Improved code quality with const modifiers and super parameters
### Removed
- Unused mention classes consolidated into plugin
- Deprecated plugins (emoji, mention, rich_editor_plugin)

## [1.1.0] - 2026-01-12
### Added
- Custom CSS styles support

## [1.0.0] - 2026-01-12
### Added
- Summernote rich text editor integration
- Plugin support for extensibility
- Smart blockquote feature
### Fixed
- Quote block rendering issues

## [0.2.0] - 2026-01-05
### Added
- Migrated from WebView to InAppWebView
- Enhanced focus/blur keyboard handling
- Beta version of keyboard show/hide functionality
### Changed
- Improved transition animations

## [0.1.0] - 2025-12-31
### Added
- Initial rich editor implementation
- UI state management
- Bottom panel for editor controls
- Toolbar with formatting options
- Mention sheet functionality
