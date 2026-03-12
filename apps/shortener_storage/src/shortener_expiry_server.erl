-module(shortener_expiry_server).
-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(CLEANUP_INTERVAL, 60000). %% Run cleanup every 60 seconds

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    erlang:send_after(?CLEANUP_INTERVAL, self(), cleanup),
    {ok, #{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(cleanup, State) ->
    delete_expired(),
    erlang:send_after(?CLEANUP_INTERVAL, self(), cleanup),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --- Internal ---

delete_expired() ->
    %% Find expired codes, evict from cache, then delete from DB
    FindSql = "SELECT short_code FROM urls WHERE expires_at IS NOT NULL AND expires_at < NOW()",
    DeleteSql = "DELETE FROM urls WHERE expires_at IS NOT NULL AND expires_at < NOW()",
    
    poolboy:transaction(shortener_db_pool, fun(Worker) ->
        case gen_server:call(Worker, {squery, FindSql}) of
            {ok, _Cols, Rows} ->
                %% Evict each expired code from ETS cache
                lists:foreach(fun({Code}) ->
                    shortener_cache:delete(Code)
                end, Rows),
                %% Now delete from DB
                gen_server:call(Worker, {squery, DeleteSql});
            _ ->
                ok
        end
    end).
