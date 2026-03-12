-module(shortener_postgres).
-behaviour(gen_server).
-behaviour(poolboy_worker).

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {conn}).

%% poolboy callback
start_link(Args) ->
    gen_server:start_link(?MODULE, Args, []).

init(Args) ->
    Host = proplists:get_value(host, Args),
    Port = proplists:get_value(port, Args),
    User = proplists:get_value(username, Args),
    Pass = proplists:get_value(password, Args),
    DB   = proplists:get_value(database, Args),
    
    case epgsql:connect(Host, User, Pass, #{database => DB, port => Port}) of
        {ok, Conn} ->
            {ok, #state{conn = Conn}};
        {error, Reason} ->
            {stop, Reason}
    end.

handle_call({squery, Sql}, _From, #state{conn = Conn} = State) ->
    Reply = epgsql:squery(Conn, Sql),
    {reply, Reply, State};

handle_call({equery, Stmt, Params}, _From, #state{conn = Conn} = State) ->
    Reply = epgsql:equery(Conn, Stmt, Params),
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, #state{conn = Conn}) ->
    epgsql:close(Conn),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
