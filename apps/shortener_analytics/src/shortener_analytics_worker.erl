-module(shortener_analytics_worker).
-behaviour(gen_server).

-export([start_link/0, track_click/3]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(FLUSH_INTERVAL, 5000). % Flush every 5 seconds

-record(state, {
    buffer = [] :: list()
}).

%% --- API ---

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

track_click(ShortCode, IpAddress, UserAgent) ->
    Timestamp = calendar:universal_time(),
    gen_server:cast(?MODULE, {track_click, ShortCode, Timestamp, IpAddress, UserAgent}).

%% --- GenServer Callbacks ---

init([]) ->
    erlang:send_after(?FLUSH_INTERVAL, self(), flush),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({track_click, ShortCode, Timestamp, IpAddress, UserAgent}, State) ->
    NewBuffer = [{ShortCode, Timestamp, IpAddress, UserAgent} | State#state.buffer],
    {noreply, State#state{buffer = NewBuffer}}.

handle_info(flush, State = #state{buffer = Buffer}) ->
    flush_to_db(lists:reverse(Buffer)),
    erlang:send_after(?FLUSH_INTERVAL, self(), flush),
    {noreply, State#state{buffer = []}};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, State) ->
    flush_to_db(lists:reverse(State#state.buffer)),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --- Internal Functions ---

flush_to_db([]) ->
    ok;
flush_to_db(Buffer) ->
    lists:foreach(fun({ShortCode, _Timestamp, IpAddress, UserAgent}) ->
        %% In a production scenario, you would batch insert these.
        %% For simplicity, we execute them individually or using a simple loop.
        Sql = "INSERT INTO analytics (short_code, ip_address, user_agent) VALUES ($1, $2, $3)",
        poolboy:transaction(shortener_db_pool, fun(Worker) ->
            gen_server:call(Worker, {equery, Sql, [ShortCode, IpAddress, UserAgent]})
        end)
    end, Buffer),
    ok.
