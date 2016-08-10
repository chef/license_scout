# opscoderl_folsom #

Opscode helpers for instrumenting Erlang apps with folsom
metrics. Here you will find the module `oc_folsom` that will help you
standardize folsom metric labels and a convenience function for
instrumenting a bit of code such that you capture the run time in a
histogram and fire a meter metric all in one call
(`oc_folsom:time/2`).

# Guidelines for opscoderl helper repos #

This repository is the first in what we hope will be a useful pattern
for collecting reusable Erlang code. The idea is to balance the
extremes of a dumping ground "commons" repo that would force consumers
to pull in dependencies that they won't use with a proliferation of
single module repos (hi, that's what this is for now, sorry).

Helper repos should follow these guidelines:

1. Be named `opscoderl_$BLAH` where `$BLAH` names a dependency that
   is wrapped (e.g. this repo with folsom) OR a well defined bit of
   functionality. I think we will soon have an `opscoderl_json` repo
   that pulls in jiffy and ej.

2. Minimal focused set of dependencies. A dependency is reasonable if
   any user of the helper will want the dependency. Conversely, a
   dependency that covers a small or rare use case should be given
   extra scrutiny. As a consumer of a helper, it is unpleasant to have
   to pull in a dependency that you aren't going to use. A tag or git
   SHA should be used by the helper to peg the version of the
   dependency.

3. Modules should be prefixed with `oc_`. Care should be taken not to
   conflict with modules from other opscoderl helper applications.

4. Open source and not product specific. May contain some
   Opscode-isms, but the intention is that these helpers can be
   generally useful (like erlware_commons).

# Guidelines for using opscoderl helpers #

1. Contrary to normal practice, avoid specifying the dependencies
   provided by the helper even if you use them directly. For example,
   depend only on `opscoderl_folsom` and use `oc_folsom` and
   `folsom`. This allows the version of the wrapped dependencies to be
   controlled by the helper app. Care needs to be taken in managing
   OTP release when a non-helper app shares a dependency with a
   helper. We may need to add direct deps in some cases to get the
   right behavior out of rebar and lock deps.


## License ##

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Copyright:**       | Copyright (c) 2013 Opscode, Inc.
| **License:**         | Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


