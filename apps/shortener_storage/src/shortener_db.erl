-module(shortener_db).

-export([save_url/2, save_url_full/5]).
-export([get_url/1, get_url_full/1]).
-export([increment_clicks/1]).

-define(POOL, shortener_db_pool).

query(Sql, Params) ->
    poolboy:transaction(?POOL, fun(Worker) ->
        gen_server:call(Worker, {equery, Sql, Params})
    end).

%% @doc Get long URL from cache or DB. Returns {ok, Url} or {error, not_found | expired}.
get_url(ShortCode) ->
    case shortener_cache:get(ShortCode) of
        {ok, LongUrl} ->
            {ok, LongUrl};
        {error, not_found} ->
            Sql = "SELECT long_url, expires_at FROM urls WHERE short_code = $1",
            case query(Sql, [ShortCode]) of
                {ok, _Cols, [{LongUrl, ExpiresAt}]} ->
                    case is_expired(ExpiresAt) of
                        true  -> {error, expired};
                        false ->
                            shortener_cache:put(ShortCode, LongUrl),
                            {ok, LongUrl}
                    end;
                {ok, _Cols, []} -> {error, not_found};
                Error -> Error
            end
    end.

%% @doc Returns {ok, LongUrl, PasswordHash | undefined}
get_url_full(ShortCode) ->
    case shortener_cache:get(ShortCode) of
        {ok, LongUrl} ->
            %% For password-protected links, we always query the DB
            check_password_hash(ShortCode, LongUrl);
        {error, not_found} ->
            Sql = "SELECT long_url, expires_at, password_hash FROM urls WHERE short_code = $1",
            case query(Sql, [ShortCode]) of
                {ok, _Cols, [{LongUrl, ExpiresAt, PwdHash}]} ->
                    case is_expired(ExpiresAt) of
                        true  -> {error, expired};
                        false ->
                            shortener_cache:put(ShortCode, LongUrl),
                            {ok, LongUrl, PwdHash}
                    end;
                {ok, _Cols, []} -> {error, not_found};
                Error -> Error
            end
    end.

check_password_hash(ShortCode, LongUrl) ->
    Sql = "SELECT password_hash FROM urls WHERE short_code = $1",
    case query(Sql, [ShortCode]) of
        {ok, _, [{Hash}]} -> {ok, LongUrl, Hash};
        _                 -> {ok, LongUrl, undefined}
    end.

save_url(LongUrl, ShortCode) ->
    save_url_full(LongUrl, ShortCode, undefined, undefined, undefined).

save_url_full(LongUrl, ShortCode, ExpiresAt, PasswordHash, WebhookUrl) ->
    Sql = "INSERT INTO urls (short_code, long_url, expires_at, password_hash, webhook_url)
           VALUES ($1, $2, $3, $4, $5)
           RETURNING short_code",
    case query(Sql, [ShortCode, LongUrl, ExpiresAt, PasswordHash, WebhookUrl]) of
        {ok, 1, _Cols, [{Code}]} ->
            shortener_cache:put(ShortCode, LongUrl),
            {ok, Code};
        {error, {error, error, <<"23505">>, _, _}} ->
            {error, duplicate_code};
        Error ->
            Error
    end.

increment_clicks(ShortCode) ->
    Sql = "UPDATE urls SET click_count = click_count + 1 WHERE short_code = $1",
    query(Sql, [ShortCode]).

is_expired(null) -> false;
is_expired(undefined) -> false;
is_expired(ExpiresAt) ->
    Now = calendar:universal_time(),
    ExpiresAt =< Now.
