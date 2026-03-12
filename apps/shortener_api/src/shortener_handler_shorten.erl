-module(shortener_handler_shorten).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    Method = cowboy_req:method(Req),
    HasBody = cowboy_req:has_body(Req),
    Req2 = handle_request(Method, HasBody, Req),
    {ok, Req2, State}.

handle_request(<<"POST">>, true, Req) ->
    %% Rate limit check per IP
    {IP, _Port} = cowboy_req:peer(Req),
    IPBinary = list_to_binary(inet:ntoa(IP)),
    case shortener_rate_limiter:check_rate(IPBinary) of
        {error, rate_limited} ->
            reply_error(429, <<"Rate limit exceeded. Max 20 requests per minute.">>, Req);
        ok ->
            case cowboy_req:read_body(Req) of
                {ok, Body, Req1} ->
                    try jsone:decode(Body) of
                        #{<<"urls">> := Urls} when is_list(Urls) ->
                            %% Bulk shortening
                            process_bulk(Urls, Req1);
                        #{<<"url">> := LongUrl} = Params ->
                            CustomCode  = maps:get(<<"custom_code">>, Params, undefined),
                            Ttl         = maps:get(<<"ttl">>, Params, undefined),
                            Password    = maps:get(<<"password">>, Params, undefined),
                            WebhookUrl  = maps:get(<<"webhook_url">>, Params, undefined),
                            process_url(LongUrl, CustomCode, Ttl, Password, WebhookUrl, Req1);
                        _ ->
                            reply_error(400, <<"Missing 'url' or 'urls' field">>, Req1)
                    catch
                        _:_ ->
                            reply_error(400, <<"Invalid JSON">>, Req1)
                    end;
                _ ->
                    reply_error(400, <<"Failed to read body">>, Req)
            end
    end;
handle_request(<<"POST">>, false, Req) ->
    reply_error(400, <<"Missing body">>, Req);
handle_request(_, _, Req) ->
    cowboy_req:reply(405, Req).

process_bulk(Urls, Req) ->
    Results = lists:map(fun(Url) ->
        case shortener_core_api:validate_url(Url) of
            true ->
                Id = erlang:unique_integer([positive, monotonic]),
                ShortCode = shortener_core_api:generate_short_code(Id),
                case shortener_db:save_url(Url, ShortCode) of
                    {ok, Code} ->
                        #{<<"url">> => Url, <<"short_url">> => make_short_url(Req, Code), <<"error">> => null};
                    _ ->
                        #{<<"url">> => Url, <<"short_url">> => null, <<"error">> => <<"Database error">>}
                end;
            false ->
                #{<<"url">> => Url, <<"short_url">> => null, <<"error">> => <<"Invalid URL">>}
        end
    end, Urls),
    reply_json(200, #{<<"results">> => Results}, Req).

process_url(LongUrl, CustomCode, Ttl, Password, WebhookUrl, Req) ->
    case shortener_core_api:validate_url(LongUrl) of
        true ->
            ShortCode = case CustomCode of
                undefined ->
                    Id = erlang:unique_integer([positive, monotonic]),
                    shortener_core_api:generate_short_code(Id);
                Code ->
                    case shortener_core_api:validate_custom_code(Code) of
                        true  -> Code;
                        false -> invalid
                    end
            end,

            case ShortCode of
                invalid ->
                    reply_error(400, <<"Invalid custom code. Use 3-20 alphanumeric characters.">>, Req);
                _ ->
                    %% Hash password if provided
                    PwdHash = case Password of
                        undefined -> undefined;
                        Pwd ->
                            HashBin = crypto:hash(sha256, Pwd),
                            base64:encode(HashBin)
                    end,
                    
                    %% Compute expiry timestamp
                    ExpiresAt = case Ttl of
                        undefined -> undefined;
                        Seconds when is_integer(Seconds) ->
                            NowEpoch = erlang:system_time(second),
                            ExpiryEpoch = NowEpoch + Seconds,
                            calendar:gregorian_seconds_to_datetime(ExpiryEpoch + 62167219200);
                        _ -> undefined
                    end,

                    case shortener_db:save_url_full(LongUrl, ShortCode, ExpiresAt, PwdHash, WebhookUrl) of
                        {ok, Code} ->
                            %% Kick off metadata fetch asynchronously
                            shortener_metadata:fetch_and_store_with_code(Code, LongUrl),
                            Resp = #{
                                <<"short_url">>  => make_short_url(Req, Code),
                                <<"short_code">> => Code,
                                <<"expires_at">> => format_expires(ExpiresAt),
                                <<"protected">>  => Password =/= undefined
                            },
                            reply_json(200, Resp, Req);
                        {error, duplicate_code} ->
                            reply_error(409, <<"Short code already taken.">>, Req);
                        _ ->
                            reply_error(500, <<"Database error">>, Req)
                    end
            end;
        false ->
            reply_error(400, <<"Invalid URL format">>, Req)
    end.

reply_json(Status, Map, Req) ->
    Json = jsone:encode(Map),
    cowboy_req:reply(Status, #{<<"content-type">> => <<"application/json">>}, Json, Req).

reply_error(Status, Message, Req) ->
    reply_json(Status, #{<<"error">> => Message}, Req).

make_short_url(Req, Code) ->
    Host   = cowboy_req:host(Req),
    Scheme = cowboy_req:scheme(Req),
    Port   = integer_to_binary(cowboy_req:port(Req)),
    if
        Port =:= <<"80">> ; Port =:= <<"443">> ->
            <<Scheme/binary, "://", Host/binary, "/", Code/binary>>;
        true ->
            <<Scheme/binary, "://", Host/binary, ":", Port/binary, "/", Code/binary>>
    end.

format_expires(undefined) -> null;
format_expires({{Y,M,D},{H,Mi,S}}) ->
    list_to_binary(io_lib:format("~4..0w-~2..0w-~2..0wT~2..0w:~2..0w:~2..0wZ", [Y,M,D,H,Mi,S])).
