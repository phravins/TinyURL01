-module(shortener_handler_unlock).
-behavior(cowboy_handler).

-export([init/2]).

-define(TOKEN_TABLE, shortener_unlock_tokens).

init(Req, State) ->
    Code = cowboy_req:binding(code, Req),
    Method = cowboy_req:method(Req),
    handle(Method, Code, Req, State).

%% GET /unlock/:code — returns a simple HTML unlock form
handle(<<"GET">>, Code, Req, State) when Code =/= undefined ->
    Html = <<"<!DOCTYPE html><html><head>"
             "<meta charset='utf-8'>"
             "<title>Protected Link</title>"
             "<style>body{font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;background:#0f0f0f;color:#eee}"
             ".box{background:#1a1a1a;padding:40px;border-radius:12px;border:1px solid #333;text-align:center;min-width:320px}"
             "h2{margin:0 0 20px}input{padding:12px;width:100%;box-sizing:border-box;margin-bottom:16px;border-radius:6px;border:1px solid #444;background:#111;color:#eee}"
             "button{padding:12px 24px;width:100%;border-radius:6px;border:none;background:#6d28d9;color:#fff;font-size:16px;cursor:pointer}"
             "button:hover{background:#7c3aed}.err{color:#f87171;font-size:14px;margin-top:8px}</style>"
             "</head><body><div class='box'>"
             "<h2>&#128274; Protected Link</h2>"
             "<form method='POST'><input type='hidden' name='code' value='", Code/binary, "'>"
             "<input type='password' name='password' placeholder='Enter password' required />"
             "<button type='submit'>Unlock</button></form>"
             "</div></body></html>">>,
    Req2 = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html">>}, Html, Req),
    {ok, Req2, State};

%% POST /api/unlock/:code — verify password and issue a redirect token
handle(<<"POST">>, Code, Req, State) when Code =/= undefined ->
    {ok, Body, Req1} = cowboy_req:read_body(Req),
    Password = try
        #{<<"password">> := P} = jsone:decode(Body),
        P
    catch _:_ ->
        %% Try form-encoded
        QS = uri_string:dissect_query(Body),
        proplists:get_value(<<"password">>, QS, <<>>)
    end,
    
    Sql = "SELECT password_hash FROM urls WHERE short_code = $1",
    case poolboy:transaction(shortener_db_pool, fun(Worker) ->
        gen_server:call(Worker, {equery, Sql, [Code]})
    end) of
        {ok, _, [{StoredHash}]} ->
            case verify_password(Password, StoredHash) of
                true ->
                    %% Issue a one-time session token in ETS
                    Token = generate_token(),
                    ensure_table(),
                    ets:insert(?TOKEN_TABLE, {Token, Code, erlang:system_time(second) + 300}),
                    reply_json(200, #{<<"token">> => Token, <<"code">> => Code}, Req1, State);
                false ->
                    reply_json(403, #{<<"error">> => <<"Invalid password">>}, Req1, State)
            end;
        {ok, _, []} ->
            reply_json(404, #{<<"error">> => <<"Not Found">>}, Req1, State);
        _ ->
            reply_json(500, #{<<"error">> => <<"Database error">>}, Req1, State)
    end;

handle(_, _, Req, State) ->
    Req2 = cowboy_req:reply(405, Req),
    {ok, Req2, State}.

verify_password(Plain, Hash) ->
    %% Simple SHA-256 comparison. In production, use bcrypt via a port driver.
    crypto:hash(sha256, Plain) =:= base64:decode(Hash).

generate_token() ->
    <<A:32, B:16, C:16, D:16, E:48>> = crypto:strong_rand_bytes(16),
    list_to_binary(io_lib:format("~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b", [A, B, C, D, E])).

ensure_table() ->
    case ets:info(?TOKEN_TABLE) of
        undefined ->
            ets:new(?TOKEN_TABLE, [named_table, public, set]);
        _ ->
            ok
    end.

reply_json(Status, Map, Req, State) ->
    Json = jsone:encode(Map),
    Req2 = cowboy_req:reply(Status, #{<<"content-type">> => <<"application/json">>}, Json, Req),
    {ok, Req2, State}.
