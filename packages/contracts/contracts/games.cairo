%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le, is_in_range
from starkware.starknet.common.syscalls import get_caller_address

const GAME_STATE_WAIT = 1
const GAME_STATE_PLAY = 2
const GAME_STATE_OVER = 3

const TURN_STATE_COMMIT = 1
const TURN_STATE_REVEAL = 2

const PLAYER_1 = 1
const PLAYER_2 = 2

const HAND_SIZE = 6
const LAST_TURN = HAND_SIZE
const CARD_NOT_PLAYED = 0

const MAX_LIFE_BUFFER = 1000000
const STARTING_LIFE_POINTS = 15
const STARTING_BATTERIES = 15

struct Player:
    member address : felt
    member life_points : felt
    member batteries : felt
end

struct Turn:
    member number : felt
    member state : felt
    member start_player : felt
    member current_player : felt
    member player_1_card_index : felt
    member player_2_card_index : felt
end

struct GameSession:
    member id : felt
    member state : felt
    member player_1 : Player
    member player_2 : Player
    member turn : Turn
end

struct Card:
    member id : felt
    member turn_played : felt
    member batteries_hash : felt
    member batteries : felt
end

@storage_var
func _owner() -> (address : felt):
end

@storage_var
func _card_contract_address() -> (address : felt):
end

# Next game session id
@storage_var
func _next_session_id() -> (session_id : felt):
end

# Game Sessions identified by a session_id
@storage_var
func _game_sessions(session_id : felt) -> (game_session : GameSession):
end

# Player hands in each session
@storage_var
func _player_cards(session_id : felt, player : felt, card_index : felt) -> (card : Card):
end

#
# Constructor
#

# Initializes the contract by setting a `name` and a `symbol` to the token collection.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt, card_address
):
    _owner.write(address)
    _card_contract_address.write(card_address)
    return ()
end

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (address : felt):
    let (address) = _owner.read()
    return (address)
end

@view
func cardContract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    let (address) = _card_contract_address.read()
    return (address)
end

#
# Getters
#

# Returns the token collection symbol.
@view
func gameState{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt
) -> (game_session : GameSession):
    let (game_session) = _game_sessions.read(session_id)
    return (game_session)
end

# @view
# func playerHand{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     session_id : felt, player : felt
# ) -> (player_hand : PlayerHand):
#     # TODO add check player is PLAYER_1 or PLAYER_2
#     let (player_hand) = _player_cards.read(session_id, player)
#     return (player_hand)
# end

# @view
# func playerHands{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     session_id : felt
# ) -> (player_1_hand : PlayerHand, player_2_hand : PlayerHand):
#     let (player_1_hand) = playerHand(session_id, PLAYER_1)
#     let (player_2_hand) = playerHand(session_id, PLAYER_2)
#     return (player_1_hand, player_2_hand)
# end

#
# Externals
#

@external
func changeOwner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_addr : felt
) -> ():
    # TODO
    return ()
end

# # Game start

@external
func startGame{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    card_ids_len : felt, card_ids : felt*
) -> (session_id : felt):
    alloc_locals
    let (caller_address) = get_caller_address()
    let (session_id) = _next_session_id.read()

    _check_card_ownership(caller_address, card_ids_len, card_ids)

    _game_sessions.write(
        session_id,
        GameSession(
        session_id,
        GAME_STATE_WAIT,
        Player(
            caller_address,
            STARTING_LIFE_POINTS,
            STARTING_BATTERIES,
            ),
        Player(0, 0, 0),
        Turn(0, 0, 0, 0, 0, 0),
        ),
    )
    _store_hand(session_id, PLAYER_1, card_ids_len, card_ids)

    _next_session_id.write(session_id + 1)
    return (session_id)
end

@external
func joinGame{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt, card_ids_len : felt, card_ids : felt*
) -> ():
    alloc_locals
    let (caller_address) = get_caller_address()
    let (game_session) = _game_sessions.read(session_id)
    _check_session(game_session, GAME_STATE_WAIT)

    _check_card_ownership(caller_address, card_ids_len, card_ids)

    # rem = 1 or 2 --> rem + 1 = PLAYER_1 or PLAYER_2
    let (q, rem) = unsigned_div_rem(game_session.player_1.address + caller_address + session_id, 2)

    _game_sessions.write(
        session_id,
        GameSession(
        game_session.id,
        GAME_STATE_PLAY,
        game_session.player_1,
        Player(
            caller_address,
            STARTING_LIFE_POINTS,
            STARTING_BATTERIES,
            ),
        Turn(
            1,
            TURN_STATE_COMMIT,
            rem + 1,
            rem + 1,
            CARD_NOT_PLAYED,
            CARD_NOT_PLAYED,
            ),
        ),
    )
    _store_hand(session_id, PLAYER_2, card_ids_len, card_ids)

    return ()
end

func _store_hand{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt, player : felt, card_ids_len : felt, card_ids : felt*
) -> ():
    # TODO do this in a loop
    _player_cards.write(session_id, player, 1, Card(card_ids[0], CARD_NOT_PLAYED, 0, 0))
    _player_cards.write(session_id, player, 2, Card(card_ids[1], CARD_NOT_PLAYED, 0, 0))
    _player_cards.write(session_id, player, 3, Card(card_ids[2], CARD_NOT_PLAYED, 0, 0))
    _player_cards.write(session_id, player, 4, Card(card_ids[3], CARD_NOT_PLAYED, 0, 0))
    _player_cards.write(session_id, player, 5, Card(card_ids[4], CARD_NOT_PLAYED, 0, 0))
    _player_cards.write(session_id, player, 6, Card(card_ids[5], CARD_NOT_PLAYED, 0, 0))
    return ()
end

# Check if the game exists and is in state {state}
func _check_session{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_session : GameSession, state : felt
) -> ():
    with_attr error_message("Stark Rivals: game session does not exist."):
        assert_not_zero(game_session.state)
    end
    with_attr error_message("Stark Rivals: bad game state."):
        assert game_session.state = state
    end
    return ()
end

# Check if the turn is in state {state}
func _check_turn(game_session : GameSession, state : felt) -> ():
    with_attr error_message("Stark Rivals: bad turn state."):
        assert game_session.turn.state = state
    end
    return ()
end

# Returns the other player
func _other_player(player : felt) -> (other_player : felt):
    if player == PLAYER_1:
        return (PLAYER_2)
    else:
        return (PLAYER_1)
    end
end

# Check if player owns the card
func _check_card_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player_address : felt, card_ids_len : felt, card_ids : felt*
) -> ():
    with_attr error_message("Stark Rivals: you need 6 cards in your hand"):
        assert card_ids_len = HAND_SIZE
    end
    let (card_contract_address) = _card_contract_address.read()
    # TODO check ownership with each card
    return ()
end

# Check whose turn it is
func _check_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_session : GameSession, player_address : felt
) -> (player : felt):
    alloc_locals
    local player
    if game_session.player_1.address == player_address:
        player = PLAYER_1
    end
    if game_session.player_2.address == player_address:
        player = PLAYER_2
    end
    with_attr error_message("Stark Rivals: you are not a player in this game."):
        assert_not_zero(player)
    end
    with_attr error_message("Stark Rivals: it is not your turn to play."):
        assert player = game_session.turn.current_player
    end
    return (player)
end

# # Game loop

@external
func playCard{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt, card_index : felt, batteries_hash : felt
) -> ():
    alloc_locals
    let (caller_address) = get_caller_address()
    let (game_session) = _game_sessions.read(session_id)
    _check_session(game_session, GAME_STATE_PLAY)
    _check_turn(game_session, TURN_STATE_COMMIT)

    let (player) = _check_player(game_session, caller_address)

    let (played_card) = _player_cards.read(session_id, player, card_index)
    with_attr error_message("Stark Rivals: card already played."):
        assert played_card.turn_played = CARD_NOT_PLAYED
    end

    _player_cards.write(
        session_id,
        player,
        card_index,
        Card(played_card.id, game_session.turn.number, batteries_hash, 0),
    )

    let (player_1_card, player_2_card) = _get_card_indexes_being_played(
        game_session, player, card_index
    )

    let (local other_player) = _other_player(player)
    local turn_state
    if game_session.turn.start_player == player:
        turn_state = TURN_STATE_COMMIT
    else:
        turn_state = TURN_STATE_REVEAL
        other_player = player
    end

    _game_sessions.write(
        session_id,
        GameSession(
        game_session.id,
        game_session.state,
        game_session.player_1,
        game_session.player_2,
        Turn(
            game_session.turn.number,
            turn_state,
            game_session.turn.start_player,
            other_player,
            player_1_card,
            player_2_card,
            ),
        ),
    )

    return ()
end

# Returns the cards being played this turn
func _get_card_indexes_being_played{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(game_session : GameSession, player : felt, card_index : felt) -> (
    player_1_card_index : felt, player_2_card_index : felt
):
    if player == PLAYER_1:
        return (card_index, game_session.turn.player_2_card_index)
    else:
        return (game_session.turn.player_1_card_index, card_index)
    end
end

# Returns the card played this turn by the player
func _get_played_card{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_session : GameSession, player : felt
) -> (played_card_index : felt, played_card : Card):
    if player == PLAYER_1:
        let (played_card) = _player_cards.read(
            game_session.id, player, game_session.turn.player_1_card_index
        )
        return (game_session.turn.player_1_card_index, played_card)
    else:
        let (played_card) = _player_cards.read(
            game_session.id, player, game_session.turn.player_2_card_index
        )
        return (game_session.turn.player_2_card_index, played_card)
    end
end

# Check batteries and hash
func _check_hash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    played_card : Card, batteries : felt, seed : felt
) -> ():
    let (revealed_hash) = hash2{hash_ptr=pedersen_ptr}(batteries, seed)
    with_attr error_message("Stark Rivals: batteries and seed do not match the hash."):
        assert revealed_hash = played_card.batteries_hash
    end
    return ()
end

# Reveal the batteries to play the turn
@external
func revealBatteries{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt, batteries : felt, seed : felt
) -> ():
    let (caller_address) = get_caller_address()
    let (game_session) = _game_sessions.read(session_id)
    _check_session(game_session, GAME_STATE_PLAY)
    _check_turn(game_session, TURN_STATE_REVEAL)

    let (player) = _check_player(game_session, caller_address)
    let (played_card_index, played_card) = _get_played_card(game_session, player)
    _check_hash(played_card, batteries, seed)
    _player_cards.write(
        session_id,
        player,
        played_card_index,
        Card(
        played_card.id,
        played_card.turn_played,
        played_card.batteries_hash,
        batteries,
        ),
    )

    if game_session.turn.start_player != player:
        _game_sessions.write(
            session_id,
            GameSession(
            game_session.id,
            game_session.state,
            game_session.player_1,
            game_session.player_2,
            Turn(
                game_session.turn.number,
                game_session.turn.state,
                game_session.turn.start_player,
                game_session.turn.start_player,
                game_session.turn.player_1_card_index,
                game_session.turn.player_2_card_index,
                ),
            ),
        )
    else:
        _complete_turn(game_session)
    end
    return ()
end

struct INFTCard:
    member lasers : felt
    member rockets : felt
end

@storage_var
func card_nft_contract(id : felt) -> (nft_card : INFTCard):
end

func _fetch_nft_card{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : felt
) -> (nft_card : INFTCard):
    let (nft_card) = card_nft_contract.read(id)
    return (nft_card)
end

func _complete_turn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_session : GameSession
) -> ():
    alloc_locals
    let (player_1_played_card) = _player_cards.read(
        game_session.id, PLAYER_1, game_session.turn.player_1_card_index
    )
    let (player_2_played_card) = _player_cards.read(
        game_session.id, PLAYER_2, game_session.turn.player_2_card_index
    )

    let (player_1_nft_card) = _fetch_nft_card(player_1_played_card.id)
    let (player_2_nft_card) = _fetch_nft_card(player_2_played_card.id)

    let player_1_damage = player_1_nft_card.lasers * (1 + player_1_played_card.batteries)
    let player_2_damage = player_2_nft_card.lasers * (1 + player_2_played_card.batteries)

    let (winner) = _get_winner(game_session.turn.start_player, player_1_damage, player_2_damage)
    let (next_start_player) = _other_player(game_session.turn.start_player)

    let (updated_player_1, updated_player_2) = _update_players(
        game_session,
        winner,
        player_1_played_card,
        player_2_played_card,
        player_1_nft_card,
        player_2_nft_card,
    )

    local updated_game_state = GAME_STATE_PLAY
    if game_session.turn.number == LAST_TURN:
        updated_game_state = GAME_STATE_OVER
    end

    if game_session.player_1.life_points == 0:
        updated_game_state = GAME_STATE_OVER
    end
    if game_session.player_2.life_points == 0:
        updated_game_state = GAME_STATE_OVER
    end

    _game_sessions.write(
        game_session.id,
        GameSession(
        game_session.id,
        updated_game_state,
        updated_player_1,
        updated_player_2,
        Turn(
            game_session.turn.number + 1,
            TURN_STATE_COMMIT,
            next_start_player,
            next_start_player,
            CARD_NOT_PLAYED,
            CARD_NOT_PLAYED,
            ),
        ),
    )
    return ()
end

# Updates players from turn data
func _update_players{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_session : GameSession,
    winner : felt,
    player_1_played_card : Card,
    player_2_played_card : Card,
    player_1_nft_card : INFTCard,
    player_2_nft_card : INFTCard,
) -> (updated_player_1 : Player, updated_player_2 : Player):
    if winner == PLAYER_1:
        let (updated_life) = _value_or_zero(
            game_session.player_2.life_points - player_1_nft_card.rockets
        )
        return (
            Player(
            game_session.player_1.address,
            game_session.player_1.life_points,
            game_session.player_1.batteries - player_1_played_card.batteries,
            ),
            Player(
            game_session.player_2.address,
            updated_life,
            game_session.player_2.batteries - player_2_played_card.batteries,
            ),
        )
    else:
        let (updated_life) = _value_or_zero(
            game_session.player_1.life_points - player_2_nft_card.rockets
        )
        return (
            Player(
            game_session.player_1.address,
            updated_life,
            game_session.player_1.batteries - player_1_played_card.batteries,
            ),
            Player(
            game_session.player_2.address,
            game_session.player_2.life_points,
            game_session.player_2.batteries - player_2_played_card.batteries,
            ),
        )
    end
end

func _value_or_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    value : felt
) -> (value_or_zero : felt):
    let (in_range) = is_in_range(value, 0, MAX_LIFE_BUFFER)
    if in_range == 1:
        return (value)
    end
    return (0)
end

func _get_winner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    start_player : felt, player_1_damage : felt, player_2_damage : felt
) -> (winner : felt):
    let (is_damage_le) = is_le(player_1_damage, player_2_damage)
    if player_1_damage == player_2_damage:
        return (start_player)
    else:
        if is_damage_le == 1:
            return (PLAYER_2)
        else:
            return (PLAYER_1)
        end
    end
end
