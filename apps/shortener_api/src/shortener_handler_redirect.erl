-module(shortener_handler_redirect).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    case cowboy_req:binding(code, Req) of
        undefined ->
            {ok, cowboy_req:reply(400, Req), State};
        Code ->
            %% Get client IP and User-Agent for analytics
            {IP, _Port} = cowboy_req:peer(Req),
            IPBinary = list_to_binary(inet:ntoa(IP)),
            UserAgent = cowboy_req:header(<<"user-agent">>, Req, <<"Unknown">>),
            
            %% Track click asynchronously
            shortener_analytics_worker:track_click(Code, IPBinary, UserAgent),
            
            %% Actually redirect if found
            case shortener_db:get_url(Code) of
                {ok, LongUrl} ->
                    %% Increment clicks asynchronously
                    shortener_db:increment_clicks(Code),
                    Req2 = cowboy_req:reply(302, #{<<"location">> => LongUrl}, Req),
                    {ok, Req2, State};
                {error, not_found} ->
                    Req2 = cowboy_req:reply(404, #{}, <<"URL not found">>, Req),
                    {ok, Req2, State}
            end
    end.
