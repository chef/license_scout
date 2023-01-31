# license_scout  

[![Build Status](https://travis-ci.org/chef/license_scout.svg?branch=1-stable)](https://travis-ci.org/chef/license_scout)

LicenseScout discovers and collects the licenses of a project and its
dependencies, including transitive dependencies.

Currently supported project types are:
 
* Chef - Berkshelf
* Erlang - rebar
* Golang - godeps
* Javascript - npm
* Perl - CPAN
* Ruby - bundler

## Usage

```bash
$ bin/license_scout /dir/to/scout/successfully/

$ bin/license_scout /dir/to/scout/unsuccessfully/
Dependency 'gopkg.in_yaml.v2' version '53feefa2559fb8dfa8d81baad31be332c97d6c77' under 'go_godep' is missing license information.
>> Found 41 dependencies for go_godep. 40 OK, 1 with problems
```

Detailed instructions for fixing licensing failures found by license_scout are now provided in the script's output. See [bin/license_scout](bin/license_scout) for more details.

## Contributing

This project is maintained by the contribution guidelines identified for
[chef](https://github.com/chef/chef) project. You can find the guidelines here:

https://github.com/chef/chef/blob/master/CONTRIBUTING.md

Pull requests in this project are merged when they have two :+1:s from maintainers.

## Maintainers

- [Dan DeLeo](https://github.com/danielsdeleo)
- [Ryan Cragun](https://github.com/ryancragun)
