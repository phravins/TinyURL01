-module(shortener_core_api).

-export([generate_short_code/1, validate_url/1, validate_custom_code/1]).

%% @doc Generates a Base62 shortcode from an ID (e.g., database sequence ID).
%%      Pads with '0' if the generated code is too short (less than 6 chars).
-spec generate_short_code(integer()) -> binary().
generate_short_code(Id) ->
    Encoded = shortener_base62:encode(Id),
    Padded = string:right(Encoded, 6, $0),
    list_to_binary(Padded).

-spec validate_url(binary()) -> boolean().
validate_url(Url) ->
    shortener_validator:is_valid_url(Url).

-spec validate_custom_code(binary()) -> boolean().
validate_custom_code(Code) ->
    shortener_validator:is_valid_custom_code(Code).
