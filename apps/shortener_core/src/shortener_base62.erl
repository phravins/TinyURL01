-module(shortener_base62).

-export([encode/1, decode/1]).

-define(ALPHABET, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").
-define(BASE, 62).

%% @doc Encode an integer into a Base62 string.
-spec encode(integer()) -> string().
encode(0) ->
    [lists:nth(1, ?ALPHABET)];
encode(N) when N > 0 ->
    encode(N, []).

encode(0, Acc) ->
    Acc;
encode(N, Acc) ->
    Rem = N rem ?BASE,
    Char = lists:nth(Rem + 1, ?ALPHABET),
    encode(N div ?BASE, [Char | Acc]).

%% @doc Decode a Base62 string back to an integer.
-spec decode(string() | binary()) -> integer().
decode(Str) when is_binary(Str) ->
    decode(binary_to_list(Str));
decode(Str) when is_list(Str) ->
    lists:foldl(
        fun(Char, Acc) ->
            Acc * ?BASE + (string:chr(?ALPHABET, Char) - 1)
        end,
        0,
        Str
    ).
