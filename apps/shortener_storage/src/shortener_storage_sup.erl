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

    DbHost = os:getenv("DB_HOST", "localhost"),
    DbPort = list_to_integer(os:getenv("DB_PORT", "5432")),
    DbUser = os:getenv("DB_USER", "postgres"),
    DbPass = os:getenv("DB_PASS", "postgres"),
    DbName = os:getenv("DB_NAME", "shortener"),

    PoolArgs = [
        {name, {local, shortener_db_pool}},
        {worker_module, shortener_postgres},
        {size, 10},
        {max_overflow, 20}
    ],

    DBArgs = [
        {host, DbHost},
        {port, DbPort},
        {username, DbUser},
        {password, DbPass},
        {database, DbName}
    ],

    CacheSpec = #{
        id      => shortener_cache,
        start   => {shortener_cache, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type    => worker,
        modules => [shortener_cache]
    },

    DistCacheSpec = #{
        id      => shortener_distributed_cache,
        start   => {shortener_distributed_cache, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type    => worker,
        modules => [shortener_distributed_cache]
    },

    ExpirySpec = #{
        id      => shortener_expiry_server,
        start   => {shortener_expiry_server, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type    => worker,
        modules => [shortener_expiry_server]
    },

    PoolSpec = poolboy:child_spec(shortener_db_pool, PoolArgs, DBArgs),

    ChildSpecs = [CacheSpec, PoolSpec, DistCacheSpec, ExpirySpec],
    {ok, {SupFlags, ChildSpecs}}.
