-module(shortener_handler_qr).
-behavior(cowboy_handler).

-export([init/2]).

-define(QR_SERVICE, "https://api.qrserver.com/v1/create-qr-code/?size=256x256&data=").

init(Req, State) ->
    case cowboy_req:binding(code, Req) of
        undefined ->
            Req2 = cowboy_req:reply(400, #{}, <<"Missing code">>, Req),
            {ok, Req2, State};
        Code ->
            Scheme = cowboy_req:scheme(Req),
            Host   = cowboy_req:host(Req),
            Port   = cowboy_req:port(Req),
            
            ShortUrl = build_short_url(Scheme, Host, Port, Code),
            Encoded  = uri_string:quote(binary_to_list(ShortUrl)),
            QrUrl    = list_to_binary(?QR_SERVICE ++ Encoded),
            
            %% Redirect to the QR code image service
            Req2 = cowboy_req:reply(302, #{<<"location">> => QrUrl}, Req),
            {ok, Req2, State}
    end.

build_short_url(Scheme, Host, Port, Code) ->
    PortBin = integer_to_binary(Port),
    if
        PortBin =:= <<"80">> ; PortBin =:= <<"443">> ->
            <<Scheme/binary, "://", Host/binary, "/", Code/binary>>;
        true ->
            <<Scheme/binary, "://", Host/binary, ":", PortBin/binary, "/", Code/binary>>
    end.
