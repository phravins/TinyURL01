-module(shortener_api_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/api/shorten", shortener_handler_shorten, []},
            {"/api/stats/:code", shortener_handler_stats, []},
            {"/:code", shortener_handler_redirect, []}
        ]}
    ]),
    
    Port = application:get_env(shortener_api, port, 8080),
    
    {ok, _} = cowboy:start_clear(http,
        [{port, Port}],
        #{env => #{dispatch => Dispatch}}
    ),
    
    shortener_api_sup:start_link().

stop(_State) ->
    ok.
