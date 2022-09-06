# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_lt, assert_nn_le
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.alloc import alloc



@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(addresses_len: felt, addresses : felt*):
    alloc_locals
    register_players(addresses_len, addresses)
    return ()
end


# Struct Enum for the game state
struct matchState:
    member join : felt
    member choose : felt
    member reveal : felt
    member settle : felt
    member p_layer : felt
    member winner : felt
end
struct matches:
member gameId:felt
end
struct MatchPlayers:
member firstPlayer : felt
member secondPlayer : felt
end


struct matchStore:
member matchId : felt
member champ : felt
member loser : felt
member drawn : felt
end


struct PlayerInfo:
    member played : felt
    member submitted : felt
    member choice : felt
    member revealed : felt
    member settled : felt
    member allowed : felt
end
 

struct playerResults:
    member player0ne : felt
    member playerTwo : felt
end
const Rock = 1
const Paper = 2
const Scissors = 3

# stores the players in a game
# will check the player input later

@storage_var
func player_info(user_address: felt) -> (res : PlayerInfo):
end
@storage_var
func _players() -> (res : playerResults):
end

@storage_var
func _totalGames() -> (res : matches):
end

@storage_var
func _matchrecord(matchId) -> (res : matchStore):
end

@storage_var
func _matchplayers() -> (res : MatchPlayers):
end

@storage_var
func _matchstates() -> (res : matchState):
end

# Getting the state of the match

@view
func get_state{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}() -> (state: matchState):
    let (state) = _matchstates.read()
    return (state)
end

@view
func get_player_Results{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}() -> (results: playerResults):
    let (results) = _players.read()
    return (results)
end

@view
func get_TotalGames{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}() -> (mat: matches):
    let (mat) = _totalGames.read()
    return (mat)
end
@view
func get_matchResults{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(id : felt) -> (match_results: matchStore):
    let (match_results) = _matchrecord.read(id)
    return (match_results)
end



@view
func get_playerInfo{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(user : felt) -> (playerstate: PlayerInfo):
    let (playerstate) = player_info.read(user)
    return (playerstate)
end

func register_players{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(addresses_len: felt, addresses : felt*):
    # No voters left
    if addresses_len == 0:
        return ()
    end
    
    let p_info = PlayerInfo(
        played=0,
        submitted=0,
        choice=0,
        revealed=0,
        settled=0,
        allowed=1,
    )
    player_info.write(addresses[addresses_len - 1], p_info) 
    
    # Go to the next voter 
    return register_players(addresses_len - 1, addresses)
end

func assert_allowed_to_play{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(info : PlayerInfo):
    # We check if caller is allowed to vote
    with_attr error_message("Address not allowed to vote."):
        assert_not_zero(info.allowed)
    end

    return ()
end

func assert_did_not_play{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(info : PlayerInfo):
    # We check if caller hasn't already voted
    with_attr error_message("Address already voted."):
        assert info.played = 0
    end
    return ()
end


@external
func joining{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(play : felt) -> ():
    alloc_locals
    let (caller) = get_caller_address()
    let (info) = player_info.read(caller)

    assert_allowed_to_play(info)
    assert_did_not_play(info)
    assert play = 1

    # Set voted flag to true
    let p_info = PlayerInfo(
        played=1,
        submitted=0,
        choice=0,
        revealed=0,
        settled=0,
        allowed=1
    )
    
    let (play_state) = player_info.read(caller)
    assert play_state.allowed = 1
    assert play_state.played = 0
    player_info.write(caller, p_info)
    let (state) = _matchstates.read()
    assert_nn_le(state.join, 2)
    let (match_players) = _matchplayers.read()
    if match_players.firstPlayer == 0:
        _matchplayers.write(MatchPlayers(firstPlayer=caller, secondPlayer=0))
    else:
        _matchplayers.write(MatchPlayers(firstPlayer=match_players.firstPlayer, secondPlayer=caller))

    end
    
    # Add positive/negative vote
    local new_state : matchState
    assert new_state.join = state.join + 1
    assert new_state.choose = state.choose
    assert new_state.reveal = state.reveal
    assert new_state.settle = state.settle
    assert new_state.p_layer = state.p_layer + 1
    assert new_state.winner = state.winner
    
    _matchstates.write(new_state)
    return ()
end



@external
func submitting{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(choose : felt) -> ():
    alloc_locals
    let (caller) = get_caller_address()
    let (info) = player_info.read(caller)

   
    assert_not_zero(choose)
    assert_nn_le(choose, 3)

    # Set voted flag to true
  
    let (play_state) = player_info.read(caller)
    assert play_state.played = 1
    assert play_state.choice = 0
    
    player_info.write(caller, PlayerInfo(played=play_state.played, submitted=1, choice=choose, revealed=play_state.revealed, settled=play_state.settled, allowed=play_state.allowed))
    let (state) = _matchstates.read()
    assert_not_zero(state.join)
    assert_nn_le(state.join, 2)
    _matchstates.write(matchState(join=state.join, choose=state.choose + 1, reveal=state.reveal, settle=state.settle, p_layer=state.p_layer, winner=state.winner))

    return ()
end

@external
func revealing{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    let (match_players) = _matchplayers.read()
    let (results) = _players.read()
    let (player1_state) = player_info.read(match_players.firstPlayer)
    let (player2_state) = player_info.read(match_players.secondPlayer)
    let (state) = _matchstates.read()
    assert state.choose = 2
    
    player_info.write(match_players.firstPlayer, PlayerInfo(played=player1_state.played, submitted=player1_state.submitted, choice=player1_state.choice, revealed=1, settled=player1_state.settled, allowed=player1_state.allowed))
    player_info.write(match_players.secondPlayer, PlayerInfo(played=player2_state.played, submitted=player2_state.submitted, choice=player2_state.choice, revealed=1, settled=player2_state.settled, allowed=player2_state.allowed))
    
    _players.write(playerResults(player0ne=player1_state.choice, playerTwo=player2_state.choice))
    let (new_state) = _matchstates.read()
    _matchstates.write(matchState(join=new_state.join, choose=new_state.choose, reveal=1, settle=new_state.settle, p_layer=new_state.p_layer, winner=new_state.winner))
   
    return ()
end

@external
func set_tling{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}():
    alloc_locals
    let (match_players) = _matchplayers.read()
    let (results) = _players.read()
    let (player1_state) = player_info.read(match_players.firstPlayer)
    let (player2_state) = player_info.read(match_players.secondPlayer)
    let (state) = _matchstates.read()
    assert state.reveal = 1

    assert_not_zero(results.player0ne)
    assert_not_zero(results.playerTwo)

   
    let (new_totalmatches) = _totalGames.read()
    _totalGames.write(matches(gameId=new_totalmatches.gameId +1))
    let (totalmatches) = _totalGames.read()
  

    if results.player0ne == results.playerTwo:
    _matchrecord.write(totalmatches.gameId, matchStore(matchId=totalmatches.gameId, champ=0, loser=0, drawn=1))
    return ()
    end
    let ans2 = results.playerTwo
    if results.player0ne == 3:
    let ans1 = 3
        if ans2 == 1:
        _matchrecord.write(totalmatches.gameId, matchStore(matchId=totalmatches.gameId, champ=match_players.secondPlayer, loser=match_players.firstPlayer, drawn=0))
        else: 
        _matchrecord.write(totalmatches.gameId, matchStore(matchId=totalmatches.gameId, champ=match_players.firstPlayer, loser=match_players.secondPlayer, drawn=0))
        return ()
        end
    ret
    end
    if results.player0ne == 2:
    let ans1 = 2
        if ans2 == 1 :
        _matchrecord.write(totalmatches.gameId, matchStore(matchId=totalmatches.gameId, champ=match_players.firstPlayer, loser=match_players.secondPlayer, drawn=0))
        return()
        else:
        _matchrecord.write(totalmatches.gameId, matchStore(matchId=totalmatches.gameId, champ=match_players.secondPlayer, loser=match_players.firstPlayer, drawn=0))
        return()
        end
    ret
    end

    if results.player0ne == 1:
    let ans1 = 0
        if ans2 == 1 :
        _matchrecord.write(totalmatches.gameId, matchStore(matchId=totalmatches.gameId, champ=match_players.secondPlayer, loser=match_players.firstPlayer, drawn=0))
        return()
        else:
        _matchrecord.write(totalmatches.gameId, matchStore(matchId=totalmatches.gameId, champ=match_players.firstPlayer, loser=match_players.secondPlayer, drawn=0))
        return()
        end
    ret
    end
    reset()

    return()
    
end

func reset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
alloc_locals
        let (state) = _matchstates.read()
        local new_state : matchState
        new_state.join = 0
        new_state.choose = 0
        new_state.reveal = 0
        new_state.settle = 0
        new_state.p_layer = 0
        new_state.winner = 0
        _matchstates.write(new_state)
    return ()
end