<!-- usage documentation: http://expeditor-docs.es.chef.io/configuration/changelog/ -->

<!-- latest_release 2.6.0 -->
## [v2.6.0](https://github.com/chef/license_scout/tree/v2.6.0) (2020-10-12)

#### Merged Pull Requests
- update ruby version to 2.6 [#243](https://github.com/chef/license_scout/pull/243) ([jayashrig158](https://github.com/jayashrig158))
- Fix chefstyle violations. [#238](https://github.com/chef/license_scout/pull/238) ([phiggins](https://github.com/phiggins))
<!-- latest_release -->

<!-- release_rollup since=2.5.1 -->
### Changes since 2.5.1 release

#### Merged Pull Requests
- update ruby version to 2.6 [#243](https://github.com/chef/license_scout/pull/243) ([jayashrig158](https://github.com/jayashrig158)) <!-- 2.6.0 -->
- Fix chefstyle violations. [#238](https://github.com/chef/license_scout/pull/238) ([phiggins](https://github.com/phiggins)) <!-- 2.5.2 -->
- do not fail when unable to find a transitive hab dependency [#218](https://github.com/chef/license_scout/pull/218) ([nellshamrell](https://github.com/nellshamrell)) <!-- 2.5.2 -->
<!-- release_rollup -->

<!-- latest_stable_release -->
## [v2.5.1](https://github.com/chef/license_scout/tree/v2.5.1) (2020-04-08)

#### Merged Pull Requests
- gomod: support vendored dependencies [#233](https://github.com/chef/license_scout/pull/233) ([stevendanna](https://github.com/stevendanna))
<!-- latest_stable_release -->

## [v2.5.0](https://github.com/chef/license_scout/tree/v2.5.0) (2020-04-06)

#### Merged Pull Requests
- Fix unit tests on master [#231](https://github.com/chef/license_scout/pull/231) ([tduffield](https://github.com/tduffield))
- Add support for go mod dependencies [#230](https://github.com/chef/license_scout/pull/230) ([tsenart](https://github.com/tsenart))
- Minor cleanup to the gomod plugin [#232](https://github.com/chef/license_scout/pull/232) ([tduffield](https://github.com/tduffield))

## [v2.4.0](https://github.com/chef/license_scout/tree/v2.4.0) (2019-10-04)

#### Merged Pull Requests
- Leverage the new &#39;v2&#39; Habitat builds in Expeditor [#201](https://github.com/chef/license_scout/pull/201) ([tduffield](https://github.com/tduffield))
- Migrate tests to buildkite [#203](https://github.com/chef/license_scout/pull/203) ([jaymalasinha](https://github.com/jaymalasinha))
- Add flag that allows you to easily search all subdirectories [#210](https://github.com/chef/license_scout/pull/210) ([tduffield](https://github.com/tduffield))
- Add rust support [#216](https://github.com/chef/license_scout/pull/216) ([nellshamrell](https://github.com/nellshamrell))

## [v2.2.0](https://github.com/chef/license_scout/tree/v2.2.0) (2019-03-15)

#### Merged Pull Requests
- Add project alias [#192](https://github.com/chef/license_scout/pull/192) ([tduffield](https://github.com/tduffield))
- Only print failure header if we failed [#193](https://github.com/chef/license_scout/pull/193) ([tduffield](https://github.com/tduffield))
- Update supported ruby to 2.6.1 [#196](https://github.com/chef/license_scout/pull/196) ([tduffield](https://github.com/tduffield))

## [v2.1.5](https://github.com/chef/license_scout/tree/v2.1.5) (2018-10-24)

#### Merged Pull Requests
- Re-add special JSON case [#183](https://github.com/chef/license_scout/pull/183) ([tduffield](https://github.com/tduffield))

## [v2.1.4](https://github.com/chef/license_scout/tree/v2.1.4) (2018-10-24)

#### Merged Pull Requests
- Include gemspec license info [#182](https://github.com/chef/license_scout/pull/182) ([tduffield](https://github.com/tduffield))

## [v2.1.3](https://github.com/chef/license_scout/tree/v2.1.3) (2018-09-17)

#### Merged Pull Requests
- Consolidate all the gem requires and use net/http in mix [#180](https://github.com/chef/license_scout/pull/180) ([tduffield](https://github.com/tduffield))

## [v2.1.2](https://github.com/chef/license_scout/tree/v2.1.2) (2018-09-17)

#### Merged Pull Requests
- Provide better error handling for Habitat packages [#179](https://github.com/chef/license_scout/pull/179) ([tduffield](https://github.com/tduffield))

## [v2.1.1](https://github.com/chef/license_scout/tree/v2.1.1) (2018-08-24)

#### Merged Pull Requests
- Match habitat&#39;s channel fallback behavior when looking for hab dependencies [#176](https://github.com/chef/license_scout/pull/176) ([danielsdeleo](https://github.com/danielsdeleo))

## [v2.1.0](https://github.com/chef/license_scout/tree/v2.1.0) (2018-08-23)

#### Merged Pull Requests
- Add channel_for_origin Habitat configuration [#175](https://github.com/chef/license_scout/pull/175) ([stevendanna](https://github.com/stevendanna))

## [v2.0.14](https://github.com/chef/license_scout/tree/v2.0.14) (2018-08-14)

#### Merged Pull Requests
- Rescue from Net::OpenTimeout failures [#174](https://github.com/chef/license_scout/pull/174) ([tduffield](https://github.com/tduffield))

## [v2.0.13](https://github.com/chef/license_scout/tree/v2.0.13) (2018-06-15)

#### Merged Pull Requests
- Gracefully handle SocketError when downloading licenses [#167](https://github.com/chef/license_scout/pull/167) ([schisamo](https://github.com/schisamo))

## [v2.0.12](https://github.com/chef/license_scout/tree/v2.0.12) (2018-06-14)

#### Merged Pull Requests
- Update LicenseScout deps &amp; improve error handling [#165](https://github.com/chef/license_scout/pull/165) ([tduffield](https://github.com/tduffield))

## [v2.0.11](https://github.com/chef/license_scout/tree/v2.0.11) (2018-05-09)

#### Merged Pull Requests
- Set default exporter to CSV [#156](https://github.com/chef/license_scout/pull/156) ([tduffield](https://github.com/tduffield))
- Remove the use of bundler from the Habitat package [#157](https://github.com/chef/license_scout/pull/157) ([tduffield](https://github.com/tduffield))

## [v1.0.4](https://github.com/chef/license_scout/tree/v1.0.4) (2018-04-25)

## [v2.0.9](https://github.com/chef/license_scout/tree/v2.0.9) (2018-04-25)

#### Merged Pull Requests
- Support exporting Dependency Manifest to CSV [#152](https://github.com/chef/license_scout/pull/152) ([tduffield](https://github.com/tduffield))
- Add special cases for &quot;mplv1.1&quot; and &quot;mplv1.0&quot; [#154](https://github.com/chef/license_scout/pull/154) ([tduffield](https://github.com/tduffield))

## [v1.0.3](https://github.com/chef/license_scout/tree/v1.0.3) (2018-04-23)

## [v2.0.7](https://github.com/chef/license_scout/tree/v2.0.7) (2018-04-18)

#### Merged Pull Requests
- Add Habitat Package [#148](https://github.com/chef/license_scout/pull/148) ([tduffield](https://github.com/tduffield))
- Fix Habitat build - Gemfile.lock does not exist [#149](https://github.com/chef/license_scout/pull/149) ([tduffield](https://github.com/tduffield))
- Promote hab pkg when we promote the RubyGem [#150](https://github.com/chef/license_scout/pull/150) ([tduffield](https://github.com/tduffield))

## [v2.0.4](https://github.com/chef/license_scout/tree/v2.0.4) (2018-04-18)

#### Merged Pull Requests
- Few more cleanups from the 2.0 refactor [#147](https://github.com/chef/license_scout/pull/147) ([tduffield](https://github.com/tduffield))

## [v2.0.3](https://github.com/chef/license_scout/tree/v2.0.3) (2018-04-17)

#### Merged Pull Requests
- Improve the detection of NPM licenses from the package.json [#146](https://github.com/chef/license_scout/pull/146) ([tduffield](https://github.com/tduffield))

## [v1.0.2](https://github.com/chef/license_scout/tree/v1.0.2) (2018-04-17)

## [v2.0.2](https://github.com/chef/license_scout/tree/v2.0.2) (2018-04-16)

#### Bug Fixes
- Fast followups to the 2.0 release [#144](https://github.com/chef/license_scout/pull/144) ([tduffield](https://github.com/tduffield))

#### Merged Pull Requests
- Refactor License Scout [#143](https://github.com/chef/license_scout/pull/143) ([tduffield](https://github.com/tduffield))

## [v1.0.0](https://github.com/chef/license_scout/tree/v1.0.0) (2018-02-08)

#### Merged Pull Requests
- Add support for detecting Chef MLSA licenses [#136](https://github.com/chef/license_scout/pull/136) ([tduffield](https://github.com/tduffield))