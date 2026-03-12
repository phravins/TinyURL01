-module(shortener_db).

-export([save_url/2, save_custom_url/2]).
-export([get_url/1]).
-export([increment_clicks/1]).

-define(POOL, shortener_db_pool).

query(Sql, Params) ->
    poolboy:transaction(?POOL, fun(Worker) ->
        gen_server:call(Worker, {equery, Sql, Params})
    end).

get_url(ShortCode) ->
    case shortener_cache:get(ShortCode) of
        {ok, LongUrl} ->
            {ok, LongUrl};
        {error, not_found} ->
            Sql = "SELECT long_url FROM urls WHERE short_code = $1",
            case query(Sql, [ShortCode]) of
                {ok, _Columns, [{LongUrl}]} ->
                    shortener_cache:put(ShortCode, LongUrl),
                    {ok, LongUrl};
                {ok, _Columns, []} ->
                    {error, not_found};
                Error ->
                    Error
            end
    end.

save_url(LongUrl, ShortCode) ->
    Sql = "INSERT INTO urls (short_code, long_url) VALUES ($1, $2) RETURNING id",
    case query(Sql, [ShortCode, LongUrl]) of
        {ok, 1, _Columns, [{_Id}]} ->
            shortener_cache:put(ShortCode, LongUrl),
            {ok, ShortCode};
        {error, {error, error, <<"23505">>, _, _}} -> % Unique violation
            {error, duplicate_code};
        Error ->
            Error
    end.

save_custom_url(LongUrl, CustomCode) ->
    save_url(LongUrl, CustomCode).

increment_clicks(ShortCode) ->
    Sql = "UPDATE urls SET click_count = click_count + 1 WHERE short_code = $1",
    query(Sql, [ShortCode]).
