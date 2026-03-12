-module(shortener_api_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([
        {'_', [
            %% --- Core Endpoints ---
            {"/api/shorten",             shortener_handler_shorten,  []},
            {"/api/stats/:code",         shortener_handler_stats,    []},
            %% --- Advanced Endpoints ---
            {"/api/qr/:code",            shortener_handler_qr,       []},
            {"/api/preview/:code",       shortener_handler_preview,  []},
            {"/api/unlock/:code",        shortener_handler_unlock,   []},
            %% --- Admin Endpoints ---
            {"/api/admin/stats",         shortener_handler_admin,    []},
            {"/api/admin/urls",          shortener_handler_admin,    []},
            {"/api/admin/urls/:code",    shortener_handler_admin,    []},
            {"/api/admin/analytics/:code", shortener_handler_admin,  []},
            %% --- Redirect (catch-all, must be last) ---
            {"/:code",                   shortener_handler_redirect, []}
        ]}
    ]),

    Port = application:get_env(shortener_api, port, 8080),

    {ok, _} = cowboy:start_clear(http,
        [{port, Port}],
        #{env => #{dispatch => Dispatch}}
    ),

    shortener_api_sup:start_link().

stop(_State) ->
    cowboy:stop_listener(http),
    ok.
