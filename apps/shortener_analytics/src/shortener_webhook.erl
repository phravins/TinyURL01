-module(shortener_webhook).

-export([fire/2]).

%% @doc Asynchronously fires a webhook POST to the given URL with click data.
%% Uses spawn so the redirect is never blocked waiting for the webhook.
-spec fire(binary(), map()) -> ok.
fire(WebhookUrl, Payload) ->
    spawn(fun() ->
        Json = jsone:encode(Payload),
        Headers = [{"Content-Type", "application/json"}],
        httpc:request(post,
            {binary_to_list(WebhookUrl), Headers, "application/json", Json},
            [{timeout, 5000}, {connect_timeout, 3000}],
            []
        )
    end),
    ok.

%% @doc Lookup a webhook URL for a given short code.
-spec get_webhook_url(binary()) -> {ok, binary()} | {error, not_found}.
get_webhook_url(ShortCode) ->
    Sql = "SELECT webhook_url FROM urls WHERE short_code = $1 AND webhook_url IS NOT NULL",
    poolboy:transaction(shortener_db_pool, fun(Worker) ->
        case gen_server:call(Worker, {equery, Sql, [ShortCode]}) of
            {ok, _Cols, [{Url}]} -> {ok, Url};
            {ok, _Cols, []}      -> {error, not_found};
            _                    -> {error, not_found}
        end
    end).

%% @doc If a webhook is registered for this short code, fire it.
-spec notify_click(binary(), binary(), binary()) -> ok.
notify_click(ShortCode, IP, UserAgent) ->
    case get_webhook_url(ShortCode) of
        {ok, Url} ->
            fire(Url, #{
                <<"event">>      => <<"click">>,
                <<"short_code">> => ShortCode,
                <<"ip">>         => IP,
                <<"user_agent">> => UserAgent,
                <<"timestamp">>  => erlang:system_time(second)
            });
        _ ->
            ok
    end.
