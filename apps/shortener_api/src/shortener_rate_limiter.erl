-module(shortener_rate_limiter).
-behaviour(gen_server).

-export([start_link/0, check_rate/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(TABLE, shortener_rate_limiter_table).
-define(WINDOW_MS, 60000).   %% 60 second sliding window
-define(MAX_REQUESTS, 20).   %% max 20 requests per window per IP

%% --- API ---

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Returns 'ok' or '{error, rate_limited}'
-spec check_rate(binary()) -> ok | {error, rate_limited}.
check_rate(IP) ->
    Now = erlang:system_time(millisecond),
    WindowStart = Now - ?WINDOW_MS,
    
    %% Fetch existing timestamps for this IP
    Timestamps = case ets:lookup(?TABLE, IP) of
        [{IP, TsL}] -> TsL;
        []          -> []
    end,
    
    %% Keep only timestamps within the current window
    Valid = [T || T <- Timestamps, T > WindowStart],
    
    if
        length(Valid) >= ?MAX_REQUESTS ->
            {error, rate_limited};
        true ->
            ets:insert(?TABLE, {IP, [Now | Valid]}),
            ok
    end.

%% --- GenServer Callbacks ---

init([]) ->
    ets:new(?TABLE, [named_table, public, set,
                     {read_concurrency, true},
                     {write_concurrency, true}]),
    %% Periodically clean up old entries every 5 minutes
    erlang:send_after(300000, self(), cleanup),
    {ok, #{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(cleanup, State) ->
    Now = erlang:system_time(millisecond),
    WindowStart = Now - ?WINDOW_MS,
    %% Remove all IP entries with no valid timestamps in the window
    ets:foldl(fun({IP, Timestamps}, _Acc) ->
        Valid = [T || T <- Timestamps, T > WindowStart],
        case Valid of
            [] -> ets:delete(?TABLE, IP);
            _  -> ets:insert(?TABLE, {IP, Valid})
        end
    end, ok, ?TABLE),
    erlang:send_after(300000, self(), cleanup),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
