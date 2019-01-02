# Changelog
All notable changes to this project will be documented in this file.  
The format is based on [Keep a Changelog][changelog].

netorcai-cliend-d adheres to [Semantic Versioning][semver].  
Its public API includes:
- the API of the public functions of the netorcai-client D package.
- modifications due to netorcai's metaprotocol.

[//]: =========================================================================
## [Unreleased]


[//]: =========================================================================
## [1.0.1] - 2019-01-02
### Fixed
- Multi-part TCP messages were not read/sent correctly.
  These operations should now be more robust.

[//]: =========================================================================
## 1.0.0 - 2018-10-29
- Initial release.

[//]: =========================================================================
[changelog]: http://keepachangelog.com/en/1.0.0/
[semver]: http://semver.org/spec/v2.0.0.html

[Unreleased]: https://github.com/netorcai/netorcai-client-d/compare/v1.0.1...master
[1.0.1]: https://github.com/netorcai/netorcai-client-d/compare/v1.0.0...v1.0.1
