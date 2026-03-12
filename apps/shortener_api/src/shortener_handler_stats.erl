-module(shortener_handler_stats).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    case cowboy_req:binding(code, Req) of
        undefined ->
            {ok, cowboy_req:reply(400, Req), State};
        Code ->
            Sql = "SELECT long_url, click_count, created_at, expires_at, is_custom
                   FROM urls WHERE short_code = $1",
            case poolboy:transaction(shortener_db_pool,
                fun(Worker) ->
                    gen_server:call(Worker, {equery, Sql, [Code]})
                end) of

                {ok, _Cols, [{LongUrl, Clicks, CreatedAt, ExpiresAt, IsCustom}]} ->
                    Resp = #{
                        <<"short_code">>  => Code,
                        <<"long_url">>    => LongUrl,
                        <<"click_count">> => Clicks,
                        <<"created_at">>  => format_pg_time(CreatedAt),
                        <<"expires_at">>  => format_pg_time(ExpiresAt),
                        <<"is_custom">>   => IsCustom
                    },
                    Json = jsone:encode(Resp),
                    Req2 = cowboy_req:reply(200,
                        #{<<"content-type">> => <<"application/json">>}, Json, Req),
                    {ok, Req2, State};

                {ok, _Cols, []} ->
                    Req2 = cowboy_req:reply(404,
                        #{<<"content-type">> => <<"application/json">>},
                        <<"{\"error\":\"Not Found\"}">>, Req),
                    {ok, Req2, State};

                _Error ->
                    Req2 = cowboy_req:reply(500,
                        #{<<"content-type">> => <<"application/json">>},
                        <<"{\"error\":\"Database Error\"}">>, Req),
                    {ok, Req2, State}
            end
    end.

%% PostgreSQL returns timestamps as {{Y,M,D},{H,Mi,S}} tuples
format_pg_time(null) -> null;
format_pg_time(undefined) -> null;
format_pg_time({{Y, M, D}, {H, Mi, S}}) ->
    list_to_binary(io_lib:format(
        "~4..0w-~2..0w-~2..0wT~2..0w:~2..0w:~2..0wZ",
        [Y, M, D, H, Mi, S]
    )).
