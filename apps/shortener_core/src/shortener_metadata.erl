-module(shortener_metadata).

-export([fetch_and_store/1]).

%% @doc Fetches the title and og:description from a URL and stores it in url_meta.
%%      This is called asynchronously on link creation.
-spec fetch_and_store(binary()) -> ok.
fetch_and_store(LongUrl) ->
    spawn(fun() ->
        case fetch_meta(LongUrl) of
            {ok, Title, Description, OgImage} ->
                Code = find_code_for_url(LongUrl),
                case Code of
                    {ok, ShortCode} ->
                        store_meta(ShortCode, Title, Description, OgImage);
                    _ ->
                        ok
                end;
            _ ->
                ok
        end
    end),
    ok.

-spec fetch_and_store_with_code(binary(), binary()) -> ok.
fetch_and_store_with_code(ShortCode, LongUrl) ->
    spawn(fun() ->
        case fetch_meta(LongUrl) of
            {ok, Title, Description, OgImage} ->
                store_meta(ShortCode, Title, Description, OgImage);
            _ ->
                ok
        end
    end),
    ok.

fetch_meta(Url) ->
    UrlStr = binary_to_list(Url),
    case httpc:request(get, {UrlStr, [{"User-Agent", "URLShortener-Preview/1.0"}]},
                       [{timeout, 5000}, {connect_timeout, 3000}], []) of
        {ok, {{_, 200, _}, _Headers, Body}} ->
            BodyBin = list_to_binary(Body),
            Title = extract_tag(BodyBin, <<"<title">>, <<"</title>">>),
            Desc  = extract_og(BodyBin, <<"og:description">>),
            Image = extract_og(BodyBin, <<"og:image">>),
            {ok, Title, Desc, Image};
        _ ->
            {error, fetch_failed}
    end.

%% Simple HTML tag extractor
extract_tag(Html, OpenTag, CloseTag) ->
    case binary:match(Html, OpenTag) of
        {Start, Len} ->
            Rest = binary:part(Html, Start + Len, byte_size(Html) - Start - Len),
            %% Skip to end of opening tag
            case binary:match(Rest, <<">">>) of
                {TagEnd, _} ->
                    Content = binary:part(Rest, TagEnd + 1, byte_size(Rest) - TagEnd - 1),
                    case binary:match(Content, CloseTag) of
                        {End, _} -> binary:part(Content, 0, End);
                        nomatch  -> <<>>
                    end;
                nomatch ->
                    case binary:match(Rest, CloseTag) of
                        {End, _} -> binary:part(Rest, 0, End);
                        nomatch  -> <<>>
                    end
            end;
        nomatch -> <<>>
    end.

%% Extract OG meta tag content
extract_og(Html, Property) ->
    SearchStr = <<"property=\"", Property/binary, "\" content=\"">>,
    case binary:match(Html, SearchStr) of
        {Start, Len} ->
            Rest = binary:part(Html, Start + Len, byte_size(Html) - Start - Len),
            case binary:match(Rest, <<"\"">>) of
                {End, _} -> binary:part(Rest, 0, End);
                nomatch  -> <<>>
            end;
        nomatch ->
            %% Try alternate attribute order
            SearchStr2 = <<"content=\"">>,
            case binary:match(Html, SearchStr2) of
                _ -> <<>>
            end
    end.

find_code_for_url(LongUrl) ->
    Sql = "SELECT short_code FROM urls WHERE long_url = $1 ORDER BY created_at DESC LIMIT 1",
    poolboy:transaction(shortener_db_pool, fun(Worker) ->
        case gen_server:call(Worker, {equery, Sql, [LongUrl]}) of
            {ok, _Cols, [{Code}]} -> {ok, Code};
            _                     -> {error, not_found}
        end
    end).

store_meta(ShortCode, Title, Description, OgImage) ->
    Sql = "INSERT INTO url_meta (short_code, title, description, og_image)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (short_code) DO UPDATE
             SET title = EXCLUDED.title,
                 description = EXCLUDED.description,
                 og_image = EXCLUDED.og_image",
    poolboy:transaction(shortener_db_pool, fun(Worker) ->
        gen_server:call(Worker, {equery, Sql, [ShortCode, Title, Description, OgImage]})
    end).
