-module(shortener_storage_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{strategy => one_for_all,
                 intensity => 1,
                 period => 5},

    PoolArgs = [
        {name, {local, shortener_db_pool}},
        {worker_module, shortener_postgres},
        {size, 10},
        {max_overflow, 20}
    ],

    DBArgs = [
        {host, application:get_env(shortener_storage, db_host, "localhost")},
        {port, application:get_env(shortener_storage, db_port, 5432)},
        {username, application:get_env(shortener_storage, db_user, "postgres")},
        {password, application:get_env(shortener_storage, db_pass, "postgres")},
        {database, application:get_env(shortener_storage, db_name, "shortener")}
    ],

    CacheSpec = #{
        id => shortener_cache,
        start => {shortener_cache, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [shortener_cache]
    },

    PoolSpec = poolboy:child_spec(shortener_db_pool, PoolArgs, DBArgs),

    ChildSpecs = [CacheSpec, PoolSpec],
    {ok, {SupFlags, ChildSpecs}}.
