-module(shortener_analytics_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{strategy => one_for_all,
                 intensity => 1,
                 period => 5},
    ChildSpecs = [
        #{
            id => shortener_analytics_worker,
            start => {shortener_analytics_worker, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [shortener_analytics_worker]
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.
