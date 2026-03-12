-module(shortener_geoip).

-export([lookup/1]).

%% @doc Simple IP-to-country lookup.
%% In production, integrate MaxMind GeoLite2 or a local GeoIP DB.
%% This implementation checks if local env GEOIP_API_URL is configured,
%% and falls back to a basic IANA range lookup for demo purposes.
-spec lookup(binary()) -> {binary(), binary()} | {binary(), binary()}.
lookup(IP) when is_binary(IP) ->
    lookup(binary_to_list(IP));
lookup("127.0.0.1")   -> {<<"LOCAL">>,    <<"Loopback">>};
lookup("::1")         -> {<<"LOCAL">>,    <<"Loopback">>};
lookup(IP) ->
    case os:getenv("GEOIP_API_URL") of
        false ->
            %% Fallback: use ip-api.com (free tier, for development)
            Url = "http://ip-api.com/json/" ++ IP ++ "?fields=countryCode,city",
            case httpc:request(get, {Url, []}, [{timeout, 2000}], []) of
                {ok, {{_, 200, _}, _, Body}} ->
                    try jsone:decode(list_to_binary(Body)) of
                        #{<<"countryCode">> := Country, <<"city">> := City} ->
                            {Country, City};
                        _ ->
                            {<<"XX">>, <<"Unknown">>}
                    catch _:_ ->
                        {<<"XX">>, <<"Unknown">>}
                    end;
                _ ->
                    {<<"XX">>, <<"Unknown">>}
            end;
        ApiUrl ->
            Url = ApiUrl ++ "/" ++ IP,
            case httpc:request(get, {Url, []}, [{timeout, 2000}], []) of
                {ok, {{_, 200, _}, _, Body}} ->
                    try jsone:decode(list_to_binary(Body)) of
                        #{<<"country">> := Country, <<"city">> := City} ->
                            {Country, City};
                        _ ->
                            {<<"XX">>, <<"Unknown">>}
                    catch _:_ ->
                        {<<"XX">>, <<"Unknown">>}
                    end;
                _ ->
                    {<<"XX">>, <<"Unknown">>}
            end
    end.
