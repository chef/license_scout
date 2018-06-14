#!/bin/bash

set -eou pipefail

# PROMOTABLE - reference to the version used in the `/expeditor promote THING PROMOTABLE`
# TARGET_CHANNEL - the channel which we are promoting to
# HAB_AUTH_TOKEN - Authentication access token for the chef-ci account

version="${PROMOTABLE:?You must provide a PROMOTABLE}"
target_channel="${TARGET_CHANNEL:?You must provide a TARGET_CHANNEL}"

# We pipe this to jq here so we can get only the ident we care about, as there may be invalid characters
# in the full results that cause jq to exit with this:
#
# parse error: Invalid string: control characters from U+0000 through U+001F must be escaped at line 15, column 12
#
results=$(curl --silent https://willem.habitat.sh/v1/depot/channels/chef/unstable/pkgs/license_scout/$version/latest | jq '.ident')

pkg_release=$(echo "$results" | jq -r .release)

hab pkg promote "chef/license_scout/${version}/${pkg_release}" "${target_channel}"
