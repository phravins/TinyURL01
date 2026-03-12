-module(shortener_distributed_cache).
-behaviour(gen_server).

-export([start_link/0, broadcast_evict/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(CACHE_GROUP, shortener_cache_group).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @doc Broadcast a cache eviction to all nodes in the cluster.
-spec broadcast_evict(binary()) -> ok.
broadcast_evict(ShortCode) ->
    Members = pg:get_members(?CACHE_GROUP),
    lists:foreach(fun(Pid) ->
        gen_server:cast(Pid, {evict, ShortCode})
    end, Members),
    ok.

init([]) ->
    %% Join the process group for distributed cache ops
    case pg:start(?CACHE_GROUP) of
        {ok, _} -> ok;
        {error, {already_started, _}} -> ok
    end,
    pg:join(?CACHE_GROUP, self()),
    {ok, #{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({evict, ShortCode}, State) ->
    %% Evict from local ETS cache
    shortener_cache:delete(ShortCode),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
