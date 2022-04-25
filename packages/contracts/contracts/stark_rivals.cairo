%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from game_engine import GameEngine, GameEngine_Card, GameEngine_GameSession

#
# Constructor
#

# Initializes the contract by setting a `name` and a `symbol` to the token collection.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner_address : felt, card_address : felt
):
    GameEngine.set_owner(owner_address)
    GameEngine.set_card_contract(card_address)
    return ()
end

#
# Getters
#

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (address : felt):
    let (address) = GameEngine.get_owner()
    return (address)
end

@view
func cardContract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    let (address) = GameEngine.get_card_contract()
    return (address)
end

@view
func gameSession{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt
) -> (game_session : GameEngine_GameSession):
    let (game_session) = GameEngine.get_game_session(session_id)
    return (game_session)
end

@view
func playerHand{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt, player : felt
) -> (player_hand_len : felt, player_hand : GameEngine_Card*):
    let (player_hand_len, player_hand) = GameEngine.get_player_hand(session_id, player)
    return (player_hand_len, player_hand)
end

@view
func playerHands{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt
) -> (
    player_1_hand_len : felt,
    player_1_hand : GameEngine_Card*,
    player_2_hand_len : felt,
    player_2_hand : GameEngine_Card*,
):
    alloc_locals
    let (player_1_hand_len, player_1_hand) = playerHand(session_id, GameEngine.PLAYER_1)
    let (player_2_hand_len, player_2_hand) = playerHand(session_id, GameEngine.PLAYER_2)
    return (player_1_hand_len, player_1_hand, player_2_hand_len, player_2_hand)
end

#
# Externals
#

@external
func changeOwner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_address : felt
) -> ():
    GameEngine.set_owner(new_address)
    return ()
end

#
# Game loop
#

@external
func startGame{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    card_ids_len : felt, card_ids : felt*
) -> ():
    let (caller_address) = get_caller_address()
    GameEngine.start_game(caller_address, card_ids_len, card_ids)
    return ()
end

@external
func joinGame{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt, card_ids_len : felt, card_ids : felt*
) -> ():
    let (caller_address) = get_caller_address()
    GameEngine.join_game(caller_address, session_id, card_ids_len, card_ids)
    return ()
end

@external
func playCard{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt, card_index : felt, batteries_hash : felt
) -> ():
    let (caller_address) = get_caller_address()
    GameEngine.play_card(caller_address, session_id, card_index, batteries_hash)
    return ()
end

# Reveal the batteries to play the turn
@external
func revealBatteries{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    session_id : felt, batteries : felt, seed : felt
) -> ():
    let (caller_address) = get_caller_address()
    GameEngine.reveal_batteries(caller_address, session_id, batteries, seed)
    return ()
end
