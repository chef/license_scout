rebar_lock_json
===============

A minimal escript converting a rebar.lock file to json output.

Should work with any version of rebar (2 or 3)'s rebar.lock file.

Build
-----

    $ rebar3 escriptize # this also copies the escript file to bin/

Run
---

    $ bin/rebar_lock_json path/to/rebar.lock
    {"amqp_client":{"type":"git","git_url":"git:\/\/github.com\/seth\/amqp_client.git","git_ref":"7622ad8093a41b7288a1aa44dd16d3e92ce8f833"}}
