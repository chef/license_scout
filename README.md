# License Scout

License Scout is a utility that discovers and aggregates the licenses for your software project's transitive dependencies.

Currently supported Dependency Types and Dependency Managers are:

Dependency Type | Supported Dependency Managers
--- | ---
chef_cookbook | berkshelf
erlang | rebar
elixir | mix
golang | dep, godep, glide
habitat | habitat
nodejs | npm
perl | cpan
ruby | bundler

## Installation

### Ruby Gem

```
gem install license_scout
```

#### Dependencies

* If you wish to scan for `berkshelf` dependencies, you'll need to manually install the Berkshelf gem in the same Ruby as License Scout
* If you wish to scan for `mix` or `rebar` dependencies, you'll need to install Erlang OTP 18.3 or greater.

### Habitat

```
hab pkg install chef/license_scout
hab pkg binlink chef/license_scout license_scout
```

## Usage

License Scout's default behavior is to scan the current directory and return a breakdown of all the licenses it can find.

```bash
my_project $ license_scout

+------+------------+------------+---------+
| Type | Dependency | License(s) | Results |
+------+------------+------------+---------+
...
```

LicenseScout will exit `0` if it was able to find licenses for all your dependencies. Otherwise, it will exit `1`.

Under the covers, License Scout leverages [Licensee](http://ben.balter.com/licensee/) (the same Ruby Gem [GitHub](https://developer.github.com/v3/licenses/) uses to detect [OSS licenses](https://spdx.org/licenses/)). In addition to using Licensee to scan your source code for licenses, License Scout will go a step further and attempt to determine if the metadata provided by the Dependency Manager specifies which license each dependency uses. At the end of the process, License Scout will provide you a Dependency Manifest following information:

1. The name of the license(s) (the SPDX ID if the a recognized open source license).
2. The name of the file where the License Scout found the license.
3. The contents of the license file (if available).

In addition to the printout provided to STDOUT, License Scout will also save a JSON manifest of all your dependencies to disk.

```json
{
  "license_manifest_version": 2,
  "generated_on": "<DATE>",
  "name": "<YOUR_PROJECT>",
  "dependencies": [...]
}
```

For more information about the structure of JSON manifest, please check out the full [JSON Schema](lib/license_scout/data/dependency_manifest_v2_schema.json).

### Result Types

License Scout will provide a summary of the licenses it finds to STDOUT. These results are intended to provide direction as to which actions may or may not be necessary to generate a Dependency Manifest that meets all of your compliance requirements. To do this it categorizes its findings into the following results.

Result | Description
--- | ---
Flagged | License Scout was able to determine the license for this software dependency, and it is one of the licenses you have explicitly flagged. You should either remove the dependency or [add an Exception](#dependency-exceptions).
Missing | License Scout could not find any license files or license metadata associated with this dependency. You should contact the maintainer and/or specify a [Fallback License](#fallback-licenses).
Not Allowed | License Scout was able to determine the license for this software dependency, but it is not one of the licenses you have explicitly allowed. You should either remove the dependency or [add an Exception](#dependency-exceptions).
OK | There were no issues.
Undetermined | License Scout found a license file but was unable to determine (with sufficient confidence) what license that file represents. License Scout was also unable to determine the license using Dependency Manager metadata. You should contact the maintainer and/or specify a [Fallback License](#fallback-licenses).

## Advanced Usage

### Configuration File(s)

You can control License Scout's behavior by providing one or more YAML configuration files, available either locally or via HTTP, to the `--config-files` option of the CLI.

```bash
$ license_scout --config-files http://example.com/license_scout/common.yml,./.license_scout.yml
```

License Scout evalutes these files in the order they are provided, allowing you to hydrate configuration by composing multiple files together. For example, you can have a single organization-wide configuration file that specifies what licenses are allowed and project-specific configuration file that specifies exceptions and which directories to scan.

#### How multiple configuration files are handled

License Scout uses [mixlib-config](https://github.com/chef/mixlib-config) to handle it's configuration. When loading multiple configuration files, mixlib-config (and thus License Scout) will not perform deep merges of Arrays. That means that License Scout will not merge (for example) `allowed_licenses` (or `flagged_licenses`) from two different configuration files; it will only take the `allowed_licenses` value from the configuration that is loaded last. This logic does not apply to the `fallbacks` or `exceptions`, because those are defined as [`config_contexts`](lib/license_scout/config.rb). It **does** apply to the individuals types specified within the `fallbacks` or `exceptions` however.

### Allowed and Flagged Licenses

License Scout provides you with the ability to provide a list of licenses that are explicitly allowed, or a list of licenses that should be flagged for further scrutiny.

- When you specify a list of `allowed_licenses`, License Scout will exit `1` if it detects a dependency with a license other than one on the list.
- When you specify a list of `flagged_licenses`, License Scout will exit `1` if it finds a dependency with that license.

To add a license to the list of allowed or flagged licenses, you need only provide the array of licenses as a string in your configuration file. A configuration may have a list of allowed licenses _or_ flagged licenses, it cannot have both. _License Scout does not support regular expressions or glob-patterms for `allowed_licenses` or `flagged_licenses`._

```yaml
allowed_licenses:
  - Apache-2.0

# OR

flagged_licenses:
  - Apache-2.0
```

License Scout will compare these string values to the licenses it finds within the dependencies. License Scout does its best to resolve everything down to valid [SPDX IDs](https://spdx.org/licenses/), so you should specify licenses using their SDPX ID.

> _Warning: Because we cannot control how maintainers specify licenses in their metadata, there may be a situation where License Scout cannot correctly detect the intended SPDX ID. In this case, you may need to temporarily provide a temporary Fallback License in your configuration. If you encounter this situation, we encourage you to [open an Issue](https://github.com/chef/license_scout) with us._

### Dependency Exceptions

If you specify a list of allowed or flagged licenses, there may be a dependency that does not adhere to the specified license(s) for which you wish to make an exception. License Scout allows you to specify Exceptions to these lsits as part of your Configuration File.

```yaml
---
allowed_licenses:
  - Apache-2.0

exceptions:
  ruby:
    - name: bundler
      reason: Used only during .gem creation
    - name: json (1.8.3)
```

Exceptions are organized by `type` (e.g. `ruby` - see Table above). There are two elements to each exception: a `name` and a `reason`.

Property | Description
--- | ---
`name` | Can be specified by `dep-name` or `dep-name (dep-version)` where `dep-name` is the name of the dependency as it exists in the Dependency Manifest and `dep-version` can be a traditional version, git reference, or type-specific version specification such as `$pkg_version-$pkg_release` for Habitat.
`reason` | An optional string that will be included in the Dependency Manifest for documentation purposes.

Simple glob-style pattern matching _is_ supported for Exceptions, so you can have an Exception for a large collection of dependencies without enumerating them all.

```yaml
---
exceptions:
  chef_cookbook:
    - name: apache2 (5.*)
      reason: Allowed by TICKET-001
  habitat:
    - name: core/bundler (1.15.1-*)
      reason: Only used for .gem creation
  ruby:
    - name: aws-sdk-*
      reason: Exception granted by Bobo T. Clown on 2018/02/31
```

### Fallback Licenses

In situations where License Scout is unable to determine the license for a particular dependency, either because Licensee was not able to identify any of the license files or the Dependency Manager did not provide any metadata that incidated how the dependency was licensed, you'll need to provide a Fallback License in your configuration. Like Exceptions, Fallback Licenses are grouped by `type`.

```yaml
fallbacks:
  golang:
    - name: github.com/dchest/siphash
      license_id: CC0-1.0
      license_content: https://raw.githubusercontent.com/dchest/siphash/master/README.md
```

Property | Description
--- | ---
name | The name of the dependency as it appears in the JSON manifest.
license_id | The ID of the license as it appears in the JSON manifest.
license_content | A URL to a file where the raw text of the license can be downloaded.

In addition to including any files Licensee identified as potential license files (but couldn't identify), License Scout will also include the Fallback License you specified in the Dependency Manifest.

## Habitat Channel Configuration

By default License Scout searches for Habitat package in the `stable`
channel. If your build process publishes packages to another channel
by default, you can use the `channel_for_origin` habitat configuration
option:

```yaml
habitat:
  channel_for_origin:
    - origin: yourorigin
      channel: dev
    - origin: someotherorigin
      channel: prod
```

## Exporting a Dependency Manifest to another format

By default, License Scout creates the Dependency Manifest as a JSON file. We do this because it provides a single document that can be easily processed into many different forms. License Scout has the ability to also export that JSON file into other formats.

### Usage

```
license_scout export [PATH_TO_JSON_FILE] --format FORMAT
```
### Support Formats

Format | Description
--- | ---
`csv` | Export the contents of the JSON file into a CSV.


## Configuration

Value | Description | Default
--- | --- | ---
directories | The fully-qualified local paths to the directories you wish to scan | _The current working directory._ |
name | The name you want to give to the scan result. | _The basename of the first directory to be scanned._ |
output_directory | The path to the directory where the output JSON file should be saved. | _The current working directory._ |
log_level | What log information should be included in STDOUT | `info` |
allowed_licenses | Only allow dependencies to have these licenses. | `[]` |
flagged_licenses | An array of licenses that should be flagged for removal or exception. | `[]` |
exceptions | An array of Exceptions. | `[]` |
environment | A hash of additional Environment Variables to pass to [mixlib-shellout](https://github.com/chef/mixlib-shellout) | `{}` |
escript_bin | The path to the `escript` binary you wish to use when shelling out to Erlang. | `escript` |
ruby_bin | The path to the `ruby` binary you wish to use when shelling out to Ruby. | `ruby` |
cpanm_root | The path to where the cpanminus install cache is located. | `~/.cpanm` |

## Contributing

This project is maintained by the contribution guidelines identified for [chef](https://github.com/chef/chef) project. You can find the guidelines here:

https://github.com/chef/chef/blob/master/CONTRIBUTING.md

Pull requests in this project are merged when they have two :+1:s from maintainers.

## Maintainers

- [Dan DeLeo](https://github.com/danielsdeleo)
- [Tom Duffield](https://github.com/tduffield)
