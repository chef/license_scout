-module(rebar_lock_json).

-export([main/1]).

main([LockPath|_]) ->
    Deps = rebar_config:consult_lock_file(LockPath),
    Ejson = lists:map(fun dep_to_ejson/1, Deps),
    io:format("~s~n", [jsone:encode({Ejson})]).

dep_to_ejson({Name, {pkg, PkgName, PkgVersion, Hash}, Lvl}) ->
    {Name, {[{<<"type">>, <<"pkg">>},
             {<<"level">>, Lvl},
             {<<"pkg_name">>, PkgName},
             {<<"pkg_version">>, PkgVersion},
             {<<"pkg_hash">>, Hash}]}};
dep_to_ejson({Name, {git, GitUrl, {ref, GitRef}}, Lvl}) ->
    {Name, {[{<<"type">>, <<"git">>},
             {<<"level">>, Lvl},
             {<<"git_url">>, erlang:iolist_to_binary(GitUrl)},
             {<<"git_ref">>, erlang:iolist_to_binary(GitRef)}]}}.
