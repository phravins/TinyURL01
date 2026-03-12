-module(shortener_validator).

-export([is_valid_url/1, is_valid_custom_code/1]).

%% @doc Basic validation to check if the string resembles a URL (HTTP/HTTPS).
-spec is_valid_url(binary() | string()) -> boolean().
is_valid_url(Url) when is_binary(Url) ->
    is_valid_url(binary_to_list(Url));
is_valid_url(Url) when is_list(Url) ->
    case uri_string:parse(Url) of
        {error, _, _} -> false;
        #{scheme := Scheme, host := Host} when (Scheme =:= "http" orelse Scheme =:= "https") andalso Host =/= "" ->
            true;
        _ ->
            false
    end.

%% @doc Validation for custom short codes (alphanumeric, 3 to 20 chars).
-spec is_valid_custom_code(binary() | string()) -> boolean().
is_valid_custom_code(Code) when is_binary(Code) ->
    is_valid_custom_code(binary_to_list(Code));
is_valid_custom_code(Code) when is_list(Code) ->
    Len = length(Code),
    if
        Len >= 3 andalso Len <= 20 ->
            lists:all(fun is_alphanumeric/1, Code);
        true ->
            false
    end.

is_alphanumeric(C) when C >= $a, C <= $z -> true;
is_alphanumeric(C) when C >= $A, C <= $Z -> true;
is_alphanumeric(C) when C >= $0, C <= $9 -> true;
is_alphanumeric(_) -> false.
