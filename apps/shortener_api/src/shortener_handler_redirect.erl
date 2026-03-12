-module(shortener_handler_redirect).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    case cowboy_req:binding(code, Req) of
        undefined ->
            {ok, cowboy_req:reply(400, Req), State};
        Code ->
            {IP, _Port} = cowboy_req:peer(Req),
            IPBinary = list_to_binary(inet:ntoa(IP)),
            UserAgent = cowboy_req:header(<<"user-agent">>, Req, <<"Unknown">>),

            case shortener_db:get_url_full(Code) of
                {ok, LongUrl, _PasswordHash = undefined} ->
                    do_redirect(Code, LongUrl, IPBinary, UserAgent, Req, State);
                {ok, _LongUrl, _PasswordHash} ->
                    %% Link is password-protected — redirect to unlock page
                    Req2 = cowboy_req:reply(302,
                        #{<<"location">> => <<"/unlock/", Code/binary>>}, Req),
                    {ok, Req2, State};
                {error, expired} ->
                    Req2 = cowboy_req:reply(410,
                        #{<<"content-type">> => <<"application/json">>},
                        <<"{\"error\":\"This link has expired.\"}">>, Req),
                    {ok, Req2, State};
                {error, not_found} ->
                    Req2 = cowboy_req:reply(404,
                        #{<<"content-type">> => <<"application/json">>},
                        <<"{\"error\":\"URL not found.\"}">>, Req),
                    {ok, Req2, State}
            end
    end.

do_redirect(Code, LongUrl, IP, UserAgent, Req, State) ->
    %% Track click asynchronously (with geo lookup)
    shortener_analytics_worker:track_click(Code, IP, UserAgent),
    %% Fire webhook if set
    shortener_webhook:notify_click(Code, IP, UserAgent),
    %% Increment click count in DB (async)
    spawn(fun() -> shortener_db:increment_clicks(Code) end),
    Req2 = cowboy_req:reply(302, #{<<"location">> => LongUrl}, Req),
    {ok, Req2, State}.
