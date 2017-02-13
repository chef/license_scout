# license_scout

LicenseScout discovers and collects the licenses of a project and its
dependencies, including transitive dependencies.

Currently supported project types are:

* Ruby - bundler
* Erlang - rebar
* CPAN - perl
* Berkshelf - chef

## Usage

```bash
$ bin/license_scout /dir/to/scout/successfully/

$ bin/license_scout /dir/to/scout/unsuccessfully/
Dependency 'gopkg.in_yaml.v2' version '53feefa2559fb8dfa8d81baad31be332c97d6c77' under 'go_godep' is missing license information.
>> Found 41 dependencies for go_godep. 40 OK, 1 with problems
```

## Thanks

Thanks to https://github.com/basho for `config_to_json` binary which helps with parsing Erlang config files. From: https://github.com/basho/erlang_template_helper

## Contributing

This project is maintained by the contribution guidelines identified for
[chef](https://github.com/chef/chef) project. You can find the guidelines here:

https://github.com/chef/chef/blob/master/CONTRIBUTING.md

Pull requests in this project are merged when they have two :+1:s from maintainers.

## Maintainers

- [Dan DeLeo](https://github.com/danielsdeleo)
- [Serdar Sutay](https://github.com/sersut)
- [Ryan Cragun](https://github.com/ryancragun)
