-module(shortener_handler_admin).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    case auth_check(Req) of
        ok      -> route_request(Req, State);
        denied  ->
            Req2 = cowboy_req:reply(401,
                #{<<"content-type">> => <<"application/json">>},
                <<"{\"error\":\"Unauthorized\"}">>, Req),
            {ok, Req2, State}
    end.

auth_check(Req) ->
    Token = cowboy_req:header(<<"x-admin-token">>, Req, <<>>),
    AdminToken = list_to_binary(os:getenv("ADMIN_TOKEN", "admin_secret")),
    case Token =:= AdminToken of
        true  -> ok;
        false -> denied
    end.

route_request(Req, State) ->
    PathInfo = cowboy_req:path_info(Req),
    Method = cowboy_req:method(Req),
    handle(Method, PathInfo, Req, State).

%% GET /api/admin/stats
handle(<<"GET">>, [<<"stats">>], Req, State) ->
    Sql =
        "SELECT "
        "  (SELECT COUNT(*) FROM urls) AS total_urls, "
        "  (SELECT COALESCE(SUM(click_count),0) FROM urls) AS total_clicks, "
        "  (SELECT COUNT(*) FROM urls WHERE created_at >= NOW() - INTERVAL '1 day') AS new_today, "
        "  (SELECT short_code FROM urls ORDER BY click_count DESC LIMIT 1) AS top_code",
    case exec_query(Sql, []) of
        {ok, _, [{Total, Clicks, NewToday, TopCode}]} ->
            reply_json(200, #{
                <<"total_urls">>    => Total,
                <<"total_clicks">>  => Clicks,
                <<"new_today">>     => NewToday,
                <<"top_short_code">> => null_to_empty(TopCode)
            }, Req, State);
        _ ->
            reply_error(500, <<"Database error">>, Req, State)
    end;

%% GET /api/admin/urls?page=1&limit=20
handle(<<"GET">>, [<<"urls">>], Req, State) ->
    QS    = cowboy_req:parse_qs(Req),
    Page  = binary_to_integer(proplists:get_value(<<"page">>,  QS, <<"1">>)),
    Limit = binary_to_integer(proplists:get_value(<<"limit">>, QS, <<"20">>)),
    Offset = (Page - 1) * Limit,
    Sql = "SELECT short_code, long_url, click_count, created_at, expires_at
           FROM urls ORDER BY created_at DESC LIMIT $1 OFFSET $2",
    case exec_query(Sql, [Limit, Offset]) of
        {ok, _, Rows} ->
            Items = lists:map(fun({Code, LongUrl, Clicks, CreatedAt, ExpiresAt}) ->
                #{
                    <<"short_code">>  => Code,
                    <<"long_url">>    => LongUrl,
                    <<"click_count">> => Clicks,
                    <<"created_at">>  => format_time(CreatedAt),
                    <<"expires_at">>  => format_time(ExpiresAt)
                }
            end, Rows),
            reply_json(200, #{<<"page">> => Page, <<"limit">> => Limit, <<"urls">> => Items}, Req, State);
        _ ->
            reply_error(500, <<"Database error">>, Req, State)
    end;

%% DELETE /api/admin/urls/:code
handle(<<"DELETE">>, [<<"urls">>, Code], Req, State) ->
    Sql = "DELETE FROM urls WHERE short_code = $1 RETURNING short_code",
    case exec_query(Sql, [Code]) of
        {ok, _, [{_}]} ->
            shortener_cache:delete(Code),
            reply_json(200, #{<<"deleted">> => Code}, Req, State);
        {ok, _, []} ->
            reply_error(404, <<"Not Found">>, Req, State);
        _ ->
            reply_error(500, <<"Database error">>, Req, State)
    end;

%% GET /api/admin/analytics/:code — deep analytics per link
handle(<<"GET">>, [<<"analytics">>, Code], Req, State) ->
    Sql = "SELECT ip_address, user_agent, country, city, clicked_at
           FROM analytics WHERE short_code = $1 ORDER BY clicked_at DESC LIMIT 100",
    case exec_query(Sql, [Code]) of
        {ok, _, Rows} ->
            Items = lists:map(fun({IP, UA, Country, City, ClickedAt}) ->
                #{
                    <<"ip">>         => null_to_empty(IP),
                    <<"user_agent">> => null_to_empty(UA),
                    <<"country">>    => null_to_empty(Country),
                    <<"city">>       => null_to_empty(City),
                    <<"clicked_at">> => format_time(ClickedAt)
                }
            end, Rows),
            reply_json(200, #{<<"short_code">> => Code, <<"events">> => Items}, Req, State);
        _ ->
            reply_error(500, <<"Database error">>, Req, State)
    end;

handle(_, _, Req, State) ->
    reply_error(404, <<"Unknown admin route">>, Req, State).

exec_query(Sql, Params) ->
    poolboy:transaction(shortener_db_pool, fun(Worker) ->
        gen_server:call(Worker, {equery, Sql, Params})
    end).

reply_json(Status, Map, Req, State) ->
    Json = jsone:encode(Map),
    Req2 = cowboy_req:reply(Status, #{<<"content-type">> => <<"application/json">>}, Json, Req),
    {ok, Req2, State}.

reply_error(Status, Message, Req, State) ->
    reply_json(Status, #{<<"error">> => Message}, Req, State).

null_to_empty(null) -> <<>>;
null_to_empty(V) -> V.

format_time(null) -> null;
format_time({{Y, M, D}, {H, Mi, S}}) ->
    list_to_binary(io_lib:format("~4..0w-~2..0w-~2..0wT~2..0w:~2..0w:~2..0wZ", [Y, M, D, H, Mi, S])).
