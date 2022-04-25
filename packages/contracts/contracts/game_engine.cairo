%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le, is_in_range

#
# Structs
#

struct GameEngine_Player:
    member address : felt
    member life_points : felt
    member batteries : felt
end

struct GameEngine_Turn:
    member number : felt
    member state : felt
    member start_player_number : felt
    member current_player_number : felt
    member player_1_card_index : felt
    member player_2_card_index : felt
end

struct GameEngine_GameSession:
    member id : felt
    member state : felt
    member player_1 : GameEngine_Player
    member player_2 : GameEngine_Player
    member turn : GameEngine_Turn
end

struct GameEngine_Card:
    member id : felt
    member turn_played : felt
    member batteries_hash : felt
    member batteries : felt
end

#
# Storage vars
#

@storage_var
func GameEngine_owner() -> (address : felt):
end

@storage_var
func GameEngine_card_contract() -> (address : felt):
end

# Next game session id
@storage_var
func GameEngine_next_session_id() -> (session_id : felt):
end

# Game Sessions identified by a session_id
@storage_var
func GameEngine_game_sessions(session_id : felt) -> (game_session : GameEngine_GameSession):
end

# Player hands in each session
@storage_var
func GameEngine_player_cards(session_id : felt, player_number : felt, card_index : felt) -> (
    card : GameEngine_Card
):
end

struct StarkRivalsCard_Card:
    member lasers : felt
    member rockets : felt
end

@storage_var
func card_nft_contract(id : felt) -> (nft_card : StarkRivalsCard_Card):
end

#
# Events
#

@event
func new_game_session(session_id : felt):
end

namespace GameEngine:
    #
    # Constants
    #

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

    #
    # Getters
    #
    func get_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        owner_address : felt
    ):
        let (address) = GameEngine_owner.read()
        return (address)
    end

    func get_card_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        owner_address : felt
    ):
        let (address) = GameEngine_card_contract.read()
        return (address)
    end

    func get_game_session{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        session_id
    ) -> (game_session : GameEngine_GameSession):
        let (game_session) = GameEngine_game_sessions.read(session_id)
        return (game_session)
    end

    func get_player_hand{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        session_id : felt, player_number : felt
    ) -> (cards_len : felt, cards : GameEngine_Card*):
        alloc_locals
        check_correct_player_number(player_number)
        # TODO do this in a loop #2
        let (local cards : GameEngine_Card*) = alloc()
        let (card_0) = GameEngine_player_cards.read(session_id, player_number, 1)
        assert cards[0] = card_0
        let (card_1) = GameEngine_player_cards.read(session_id, player_number, 2)
        assert cards[1] = card_1
        let (card_2) = GameEngine_player_cards.read(session_id, player_number, 3)
        assert cards[2] = card_2
        let (card_3) = GameEngine_player_cards.read(session_id, player_number, 4)
        assert cards[3] = card_3
        let (card_4) = GameEngine_player_cards.read(session_id, player_number, 5)
        assert cards[4] = card_4
        let (card_5) = GameEngine_player_cards.read(session_id, player_number, 6)
        assert cards[5] = card_5
        return (6, cards)
    end

    #
    # Setters
    #

    func set_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        new_address : felt
    ) -> ():
        GameEngine_owner.write(new_address)
        return ()
    end

    func set_card_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        new_address : felt
    ) -> ():
        GameEngine_card_contract.write(new_address)
        return ()
    end

    #
    # Game Loop
    #

    func start_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller_address : felt, card_ids_len : felt, card_ids : felt*
    ) -> ():
        alloc_locals
        let (session_id) = GameEngine_next_session_id.read()

        check_card_ownership(caller_address, card_ids_len, card_ids)

        GameEngine_game_sessions.write(
            session_id,
            GameEngine_GameSession(
            session_id,
            GAME_STATE_WAIT,
            GameEngine_Player(
                caller_address,
                STARTING_LIFE_POINTS,
                STARTING_BATTERIES,
                ),
            GameEngine_Player(0, 0, 0),
            GameEngine_Turn(0, 0, 0, 0, 0, 0),
            ),
        )
        store_hand(session_id, PLAYER_1, card_ids_len, card_ids)

        GameEngine_next_session_id.write(session_id + 1)

        new_game_session.emit(session_id)
        return ()
    end

    func join_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller_address : felt, session_id : felt, card_ids_len : felt, card_ids : felt*
    ) -> ():
        alloc_locals
        let (game_session) = GameEngine_game_sessions.read(session_id)

        check_session(game_session, GAME_STATE_WAIT)
        check_card_ownership(caller_address, card_ids_len, card_ids)
        check_not_duplicate_player(caller_address, game_session)

        # rem = 1 or 2 --> rem + 1 = PLAYER_1 or PLAYER_2
        let (q, rem) = unsigned_div_rem(
            game_session.player_1.address + caller_address + session_id, 2
        )

        GameEngine_game_sessions.write(
            session_id,
            GameEngine_GameSession(
            game_session.id,
            GAME_STATE_PLAY,
            game_session.player_1,
            GameEngine_Player(
                caller_address,
                STARTING_LIFE_POINTS,
                STARTING_BATTERIES,
                ),
            GameEngine_Turn(
                1,
                TURN_STATE_COMMIT,
                rem + 1,
                rem + 1,
                CARD_NOT_PLAYED,
                CARD_NOT_PLAYED,
                ),
            ),
        )
        store_hand(session_id, PLAYER_2, card_ids_len, card_ids)

        return ()
    end

    func play_card{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller_address : felt, session_id : felt, card_index : felt, batteries_hash : felt
    ) -> ():
        alloc_locals
        let (game_session) = GameEngine_game_sessions.read(session_id)
        check_session(game_session, GAME_STATE_PLAY)
        check_turn(game_session, TURN_STATE_COMMIT)

        let (player_number) = check_player_number_turn(game_session, caller_address)

        let (played_card) = GameEngine_player_cards.read(session_id, player_number, card_index)
        with_attr error_message("Stark Rivals: card already played."):
            assert played_card.turn_played = CARD_NOT_PLAYED
        end

        GameEngine_player_cards.write(
            session_id,
            player_number,
            card_index,
            GameEngine_Card(played_card.id, game_session.turn.number, batteries_hash, 0),
        )

        let (player_1_card_index, player_2_card_index) = get_card_indexes_being_played(
            game_session, player_number, card_index
        )

        let (local _other_player_number) = other_player_number(player_number)
        local turn_state
        if game_session.turn.start_player_number == player_number:
            turn_state = TURN_STATE_COMMIT
        else:
            turn_state = TURN_STATE_REVEAL
            _other_player_number = player_number
        end

        GameEngine_game_sessions.write(
            session_id,
            GameEngine_GameSession(
            game_session.id,
            game_session.state,
            game_session.player_1,
            game_session.player_2,
            GameEngine_Turn(
                game_session.turn.number,
                turn_state,
                game_session.turn.start_player_number,
                _other_player_number,
                player_1_card_index,
                player_2_card_index,
                ),
            ),
        )
        return ()
    end

    # Reveal the batteries to play the turn
    func reveal_batteries{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller_address : felt, session_id : felt, batteries : felt, seed : felt
    ) -> ():
        alloc_locals
        let (game_session) = GameEngine_game_sessions.read(session_id)
        check_session(game_session, GAME_STATE_PLAY)
        check_turn(game_session, TURN_STATE_REVEAL)

        # TODO check battery balance (do this when playing the card)

        let (player_number) = check_player_number_turn(game_session, caller_address)
        let (played_card_index, played_card) = get_played_card(game_session, player_number)
        check_hash(played_card, batteries, seed)

        GameEngine_player_cards.write(
            session_id,
            player_number,
            played_card_index,
            GameEngine_Card(
            played_card.id,
            played_card.turn_played,
            played_card.batteries_hash,
            batteries,
            ),
        )

        if game_session.turn.start_player_number != player_number:
            GameEngine_game_sessions.write(
                session_id,
                GameEngine_GameSession(
                game_session.id,
                game_session.state,
                game_session.player_1,
                game_session.player_2,
                GameEngine_Turn(
                    game_session.turn.number,
                    game_session.turn.state,
                    game_session.turn.start_player_number,
                    game_session.turn.start_player_number,
                    game_session.turn.player_1_card_index,
                    game_session.turn.player_2_card_index,
                    ),
                ),
            )
        else:
            complete_turn(game_session)
        end
        return ()
    end

    # Updates players from turn data
    func update_players{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_session : GameEngine_GameSession,
        winner : felt,
        player_1_played_card : GameEngine_Card,
        player_2_played_card : GameEngine_Card,
        player_1_nft_card : StarkRivalsCard_Card,
        player_2_nft_card : StarkRivalsCard_Card,
    ) -> (updated_player_1 : GameEngine_Player, updated_player_2 : GameEngine_Player):
        if winner == PLAYER_1:
            let (updated_life) = value_or_zero(
                game_session.player_2.life_points - player_1_nft_card.rockets
            )
            return (
                GameEngine_Player(
                game_session.player_1.address,
                game_session.player_1.life_points,
                game_session.player_1.batteries - player_1_played_card.batteries,
                ),
                GameEngine_Player(
                game_session.player_2.address,
                updated_life,
                game_session.player_2.batteries - player_2_played_card.batteries,
                ),
            )
        else:
            let (updated_life) = value_or_zero(
                game_session.player_1.life_points - player_2_nft_card.rockets
            )
            return (
                GameEngine_Player(
                game_session.player_1.address,
                updated_life,
                game_session.player_1.batteries - player_1_played_card.batteries,
                ),
                GameEngine_Player(
                game_session.player_2.address,
                game_session.player_2.life_points,
                game_session.player_2.batteries - player_2_played_card.batteries,
                ),
            )
        end
    end

    func complete_turn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_session : GameEngine_GameSession
    ) -> ():
        alloc_locals
        let (player_1_played_card) = GameEngine_player_cards.read(
            game_session.id, PLAYER_1, game_session.turn.player_1_card_index
        )
        let (player_2_played_card) = GameEngine_player_cards.read(
            game_session.id, PLAYER_2, game_session.turn.player_2_card_index
        )

        let (player_1_nft_card) = fetch_nft_card(player_1_played_card.id)
        let (player_2_nft_card) = fetch_nft_card(player_2_played_card.id)

        let player_1_damage = player_1_nft_card.lasers * (1 + player_1_played_card.batteries)
        let player_2_damage = player_2_nft_card.lasers * (1 + player_2_played_card.batteries)

        let (winner) = get_winner(
            game_session.turn.start_player_number, player_1_damage, player_2_damage
        )
        let (next_start_player_number) = other_player_number(game_session.turn.start_player_number)

        let (updated_player_1, updated_player_2) = update_players(
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

        GameEngine_game_sessions.write(
            game_session.id,
            GameEngine_GameSession(
            game_session.id,
            updated_game_state,
            updated_player_1,
            updated_player_2,
            GameEngine_Turn(
                game_session.turn.number + 1,
                TURN_STATE_COMMIT,
                next_start_player_number,
                next_start_player_number,
                CARD_NOT_PLAYED,
                CARD_NOT_PLAYED,
                ),
            ),
        )
        return ()
    end

    func get_winner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        start_player_number : felt, player_1_damage : felt, player_2_damage : felt
    ) -> (winner : felt):
        let (is_damage_le) = is_le(player_1_damage, player_2_damage)
        if player_1_damage == player_2_damage:
            return (start_player_number)
        else:
            if is_damage_le == 1:
                return (PLAYER_2)
            else:
                return (PLAYER_1)
            end
        end
    end

    #
    # Checks
    #

    # Check player address is not already in the session
    func check_not_duplicate_player{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(caller_address : felt, game_session : GameEngine_GameSession) -> ():
        with_attr error_message("Stark Rivals: player already in the session."):
            assert_not_equal(caller_address, game_session.player_1.address)
        end
        return ()
    end

    # Check player number is valid
    func check_correct_player_number{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(player_number : felt) -> ():
        if player_number == PLAYER_1:
            return ()
        end
        if player_number == PLAYER_2:
            return ()
        end
        with_attr error_message("Stark Rivals: player number needs to be 1 or 2."):
            assert 1 = 0
        end
        return ()
    end

    # Check if player owns the card
    func check_card_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_address : felt, card_ids_len : felt, card_ids : felt*
    ) -> ():
        with_attr error_message("Stark Rivals: you need 6 cards in your hand."):
            assert card_ids_len = HAND_SIZE
        end
        let (card_contract_address) = GameEngine_card_contract.read()
        # TODO check ownership with each card
        return ()
    end

    # Check if the game exists and is in state {state}
    func check_session{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_session : GameEngine_GameSession, state : felt
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
    func check_turn(game_session : GameEngine_GameSession, state : felt) -> ():
        with_attr error_message("Stark Rivals: bad turn state."):
            assert game_session.turn.state = state
        end
        return ()
    end

    # Check whose turn it is
    func check_player_number_turn{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(game_session : GameEngine_GameSession, player_address : felt) -> (player_number : felt):
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
            assert player = game_session.turn.current_player_number
        end
        return (player)
    end

    # Check batteries and hash
    func check_hash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        played_card : GameEngine_Card, batteries : felt, seed : felt
    ) -> ():
        let (revealed_hash) = hash2{hash_ptr=pedersen_ptr}(batteries, seed)
        with_attr error_message("Stark Rivals: batteries and seed do not match the hash."):
            assert revealed_hash = played_card.batteries_hash
        end
        return ()
    end

    #
    # State
    #

    func store_hand{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        session_id : felt, player_number : felt, card_ids_len : felt, card_ids : felt*
    ) -> ():
        # TODO do this in a loop
        GameEngine_player_cards.write(
            session_id, player_number, 1, GameEngine_Card(card_ids[0], CARD_NOT_PLAYED, 0, 0)
        )
        GameEngine_player_cards.write(
            session_id, player_number, 2, GameEngine_Card(card_ids[1], CARD_NOT_PLAYED, 0, 0)
        )
        GameEngine_player_cards.write(
            session_id, player_number, 3, GameEngine_Card(card_ids[2], CARD_NOT_PLAYED, 0, 0)
        )
        GameEngine_player_cards.write(
            session_id, player_number, 4, GameEngine_Card(card_ids[3], CARD_NOT_PLAYED, 0, 0)
        )
        GameEngine_player_cards.write(
            session_id, player_number, 5, GameEngine_Card(card_ids[4], CARD_NOT_PLAYED, 0, 0)
        )
        GameEngine_player_cards.write(
            session_id, player_number, 6, GameEngine_Card(card_ids[5], CARD_NOT_PLAYED, 0, 0)
        )
        return ()
    end

    #
    # Utils
    #

    # Returns the other player number
    func other_player_number(player_number : felt) -> (other_player_number : felt):
        if player_number == PLAYER_1:
            return (PLAYER_2)
        else:
            return (PLAYER_1)
        end
    end

    # Returns the cards being played this turn
    func get_card_indexes_being_played{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(game_session : GameEngine_GameSession, player_number : felt, card_index : felt) -> (
        player_1_card_index : felt, player_2_card_index : felt
    ):
        if player_number == PLAYER_1:
            return (card_index, game_session.turn.player_2_card_index)
        else:
            return (game_session.turn.player_1_card_index, card_index)
        end
    end

    # Returns the card played this turn by the player number
    func get_played_card{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_session : GameEngine_GameSession, player_number : felt
    ) -> (played_card_index : felt, played_card : GameEngine_Card):
        if player_number == PLAYER_1:
            let (played_card) = GameEngine_player_cards.read(
                game_session.id, player_number, game_session.turn.player_1_card_index
            )
            return (game_session.turn.player_1_card_index, played_card)
        else:
            let (played_card) = GameEngine_player_cards.read(
                game_session.id, player_number, game_session.turn.player_2_card_index
            )
            return (game_session.turn.player_2_card_index, played_card)
        end
    end

    # Returns the value if lower than 0, 0 otherwise
    func value_or_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        value : felt
    ) -> (value_or_zero : felt):
        let (in_range) = is_in_range(value, 0, MAX_LIFE_BUFFER)
        if in_range == 1:
            return (value)
        end
        return (0)
    end

    #
    # Stark Rivals Card contract interactions
    #

    func fetch_nft_card{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        id : felt
    ) -> (nft_card : StarkRivalsCard_Card):
        let (nft_card) = card_nft_contract.read(id)
        return (nft_card)
    end
end
