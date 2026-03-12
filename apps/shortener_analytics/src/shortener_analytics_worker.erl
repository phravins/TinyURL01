-module(shortener_analytics_worker).
-behaviour(gen_server).

-export([start_link/0, track_click/3]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(FLUSH_INTERVAL, 5000).

-record(state, {
    buffer = [] :: list()
}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @doc Asynchronously track a click event. Geo lookup happens inside the worker.
track_click(ShortCode, IpAddress, UserAgent) ->
    gen_server:cast(?MODULE, {track_click, ShortCode, IpAddress, UserAgent}).

init([]) ->
    inets:start(),
    ssl:start(),
    erlang:send_after(?FLUSH_INTERVAL, self(), flush),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({track_click, ShortCode, IpAddress, UserAgent}, State) ->
    %% Geo lookup (may take up to 2s, runs inside worker cast)
    {Country, City} = shortener_geoip:lookup(IpAddress),
    Event = {ShortCode, IpAddress, UserAgent, Country, City},
    {noreply, State#state{buffer = [Event | State#state.buffer]}}.

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

flush_to_db([]) -> ok;
flush_to_db(Buffer) ->
    lists:foreach(fun({ShortCode, IP, UA, Country, City}) ->
        Sql = "INSERT INTO analytics (short_code, ip_address, user_agent, country, city)
               VALUES ($1, $2, $3, $4, $5)",
        poolboy:transaction(shortener_db_pool, fun(Worker) ->
            gen_server:call(Worker, {equery, Sql, [ShortCode, IP, UA, Country, City]})
        end)
    end, Buffer),
    ok.
