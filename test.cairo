%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, unsigned_div_rem
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
    member start_player_card : felt
    member second_player_card : felt
end

struct GameSession:
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
    let (caller_address) = get_caller_address()
    _game_sessions.write(
        1,
        GameSession(
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
    return ()
end

@external
func change{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(value : felt):
    let (game_session) = _game_sessions.read(1)
    _game_sessions.write(1, GameSession(player_2=Player(value, value, value)))
end

@view
func read{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    game_session : GameSession
):
    let (game_session) = _game_sessions.read(1)
    return (game_session)
end
