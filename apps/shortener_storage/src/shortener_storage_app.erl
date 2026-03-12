-module(shortener_storage_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    shortener_storage_sup:start_link().

stop(_State) ->
    ok.
