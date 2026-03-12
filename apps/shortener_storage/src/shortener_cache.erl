-module(shortener_cache).
-behaviour(gen_server).

-export([start_link/0, get/1, put/2, delete/1, clear/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(TABLE, shortener_cache_table).

%% --- API ---

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

get(Key) ->
    case ets:lookup(?TABLE, Key) of
        [{Key, Value}] -> {ok, Value};
        [] -> {error, not_found}
    end.

put(Key, Value) ->
    ets:insert(?TABLE, {Key, Value}),
    ok.

delete(Key) ->
    ets:delete(?TABLE, Key),
    ok.

clear() ->
    ets:delete_all_objects(?TABLE),
    ok.

%% --- GenServer Callbacks ---

init([]) ->
    %% public, named_table, read_concurrency for optimal cache access
    ets:new(?TABLE, [named_table, public, set, {read_concurrency, true}, {write_concurrency, true}]),
    {ok, #{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
