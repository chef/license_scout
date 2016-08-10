# Rebar Fixtures

This directory is copied from the `src/oc_erchef/deps` directory of the Chef
Server source code, after running `./rebar get-deps` in that directory.

To reduce the amount of data, everything except for top-level files has
been removed via `find . -type d -depth 2 -exec rm -rf '{}' \;`

See also:

* https://github.com/chef/chef-server
