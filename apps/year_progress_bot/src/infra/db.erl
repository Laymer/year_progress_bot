-module(db).
-export([create_schema/0, unnotified_chats/2, mark_chats_notified/2, add_notified_chat/2]).
-compile([{parse_transform, lager_transform}]).

create_schema() ->
    sumo:create_schema().

unnotified_chats(Count, Date) ->
    Chats = sumo:find_by(chats, [{notified_at, '<', Date}], Count, 0),
    lists:map(fun(Ch) -> maps:get(id, Ch) end, Chats).

mark_chats_notified(List, Date) ->
    [persist(Id, Date) || Id <- List].

persist(Id, Date) ->
    Chat = chats:new(Id, Date),
    Changeset = sumo_changeset:cast(chats, Chat, #{}, [id, notified_at]),
    Valid = sumo_changeset:validate_required(Changeset, [id, notified_at]),
    {ok, _} = sumo:persist(Valid).

add_notified_chat(Id, Date) ->
    Chat = chats:new(Id, Date),
    sumo:call(chats, persist_new, [Chat]),
    lager:debug("New chat id ~p is stored in DB.", [Id]),
    ok.
