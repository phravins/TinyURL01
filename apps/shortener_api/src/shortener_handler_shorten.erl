-module(shortener_handler_shorten).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    Method = cowboy_req:method(Req),
    HasBody = cowboy_req:has_body(Req),
    Req2 = handle_request(Method, HasBody, Req),
    {ok, Req2, State}.

handle_request(<<"POST">>, true, Req) ->
    case cowboy_req:read_body(Req) of
        {ok, Body, Req1} ->
            try jsone:decode(Body) of
                #{<<"url">> := LongUrl} ->
                    process_url(LongUrl, Req1);
                _ ->
                    reply_error(400, <<"Missing 'url' field">>, Req1)
            catch
                _:_ ->
                    reply_error(400, <<"Invalid JSON">>, Req1)
            end;
        _ ->
            reply_error(400, <<"Failed to read body">>, Req)
    end;
handle_request(<<"POST">>, false, Req) ->
    reply_error(400, <<"Missing body">>, Req);
handle_request(_, _, Req) ->
    cowboy_req:reply(405, Req).

process_url(LongUrl, Req) ->
    case shortener_core_api:validate_url(LongUrl) of
        true ->
            %% In a real app we might grab an ID from a sequence first,
            %% but for simplicity we let DB generate ID or handle custom logic
            Id = erlang:system_time(millisecond),
            ShortCode = shortener_core_api:generate_short_code(Id),
            
            case shortener_db:save_url(LongUrl, ShortCode) of
                {ok, Code} ->
                    reply_json(200, #{<<"short_url">> => make_short_url(Req, Code)}, Req);
                {error, duplicate_code} ->
                    reply_error(409, <<"Code already exists">>, Req);
                _Error ->
                    reply_error(500, <<"Database error">>, Req)
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
    Host = cowboy_req:host(Req),
    Scheme = cowboy_req:scheme(Req),
    Port = integer_to_binary(cowboy_req:port(Req)),
    %% Base URL format
    if
        Port =:= <<"80">> ; Port =:= <<"443">> ->
            <<Scheme/binary, "://", Host/binary, "/", Code/binary>>;
        true ->
            <<Scheme/binary, "://", Host/binary, ":", Port/binary, "/", Code/binary>>
    end.
