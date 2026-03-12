-module(shortener_handler_preview).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    case cowboy_req:binding(code, Req) of
        undefined ->
            reply_error(400, <<"Missing code">>, Req, State);
        Code ->
            Sql = "SELECT m.title, m.description, m.og_image, u.long_url, u.click_count
                   FROM url_meta m
                   JOIN urls u ON u.short_code = m.short_code
                   WHERE m.short_code = $1",
            case poolboy:transaction(shortener_db_pool, fun(Worker) ->
                gen_server:call(Worker, {equery, Sql, [Code]})
            end) of
                {ok, _Cols, [{Title, Desc, Image, LongUrl, Clicks}]} ->
                    Resp = #{
                        <<"short_code">>  => Code,
                        <<"long_url">>    => LongUrl,
                        <<"title">>       => null_to_empty(Title),
                        <<"description">> => null_to_empty(Desc),
                        <<"og_image">>    => null_to_empty(Image),
                        <<"click_count">> => Clicks
                    },
                    reply_json(200, Resp, Req, State);
                {ok, _, []} ->
                    %% Meta not fetched yet — try to return basic info
                    UrlSql = "SELECT long_url, click_count FROM urls WHERE short_code = $1",
                    case poolboy:transaction(shortener_db_pool, fun(W) ->
                        gen_server:call(W, {equery, UrlSql, [Code]})
                    end) of
                        {ok, _, [{LongUrl, Clicks}]} ->
                            reply_json(200, #{
                                <<"short_code">>  => Code,
                                <<"long_url">>    => LongUrl,
                                <<"title">>       => <<>>,
                                <<"description">> => <<>>,
                                <<"og_image">>    => <<>>,
                                <<"click_count">> => Clicks
                            }, Req, State);
                        _ ->
                            reply_error(404, <<"Not Found">>, Req, State)
                    end;
                _ ->
                    reply_error(500, <<"Database error">>, Req, State)
            end
    end.

reply_json(Status, Map, Req, State) ->
    Json = jsone:encode(Map),
    Req2 = cowboy_req:reply(Status, #{<<"content-type">> => <<"application/json">>}, Json, Req),
    {ok, Req2, State}.

reply_error(Status, Message, Req, State) ->
    reply_json(Status, #{<<"error">> => Message}, Req, State).

null_to_empty(null) -> <<>>;
null_to_empty(V) -> V.
