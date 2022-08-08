# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.hash import hash2

# Struct Enum for the game state
struct matchState:
    member join : felt
    member choose : felt
    member reveal : felt
    member settle : felt
end

struct playerResults:
    member encode : felt
    member decode : felt
end
const Rock = 1
const Paper = 2
const Scissors = 3
# stores the players in a game
# will check the player input later
@storage_var
func _players(player : felt) -> (res : felt):
end

@storage_var
func _encodedchoice(i : felt) -> (res : playerResults):
end

@storage_var
func _decodedchoice(i : felt) -> (res : playerResults):
end
# Stores the state of the Match
@storage_var
func _matchstates(player : felt) -> (Matchstate : matchState):
end

# Getting the state of the match
@view
func getState{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    let (playerOne) = _players.read(1)
    let (playerTwo) = _players.read(2)
    let (match_playerOne) = _matchstates.read(playerOne)
    let (match_playerTwo) = _matchstates.read(playerTwo)

    return ()
end

# view function to get the players in a game.
@view
func getPlayers{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        playerOne : felt, playerTwo : felt):
    let (playerOne) = _players.read(1)
    let (playerTwo) = _players.read(2)
    return (playerOne=playerOne, playerTwo=playerTwo)
end

# Define a storage variable.
@storage_var
func balance() -> (res : felt):
end

# Increases the balance by the given amount.

@external
func join{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(state : matchState):
    # let (state) = _matchstates.read()
    # assert state = matchState.join
    let (sender_address) = get_caller_address()
    let (match_players) = _matchstates.read(sender_address)
    assert match_players.join = 0
    let (playerOne) = _players.read(1)
    let (playerTwo) = _players.read(2)
    if playerOne == 0:
        _players.write(1, sender_address)
        _matchstates.write(playerOne, matchState(join=1, choose=0, reveal=0, settle=0))
    else:
        _players.write(2, sender_address)
        _matchstates.write(playerTwo, matchState(join=1, choose=0, reveal=0, settle=0))
    end
    return ()
end
# I will have to work on Keccak later on this one.
# Also, asserting that players are the real ones. player 2 is indeed player 2.
@external
func submitChoice{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        choice : felt, salt : felt):
    # let (state) = _matchstates.read()
    # assert state = matchState.choose
    let (sender_address) = get_caller_address()
    let (match_players) = _matchstates.read(sender_address)
    assert match_players.join = 1
    assert match_players.choose = 0
    let (playerOne) = _players.read(1)
    let (playerTwo) = _players.read(2)
    if playerOne == sender_address:
        # let (choice) = hash2{hash_ptr=pedersen_ptr}(choice, salt)
        _encodedchoice.write(1, playerResults(encode=choice, decode=0))
        _matchstates.write(playerOne, matchState(join=1, choose=1, reveal=0, settle=0))
    else:
        # let (choice) = hash2{hash_ptr=pedersen_ptr}(choice, salt)
        _encodedchoice.write(2, playerResults(encode=choice, decode=0))
        _matchstates.write(playerOne, matchState(join=1, choose=1, reveal=0, settle=0))
    end
    return ()
end

# I will have to work on Keccak on this one too.
@external
func revealChoice{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        choice : felt, salt : felt):
    # let (state) = _matchstates.read()
    # assert state = matchState.reveal
    let (sender_address) = get_caller_address()
    let (match_players) = _matchstates.read(sender_address)
    assert match_players.join = 1
    assert match_players.choose = 1
    assert match_players.reveal = 0
    let (playerOne) = _players.read(1)
    let (playerTwo) = _players.read(2)
    if playerOne == sender_address:
        # let (choice) = hash2{hash_ptr=pedersen_ptr}(choice, salt)
        let (p1results) = _encodedchoice.read(1)
        # assert choice = _encodedchoice.read(1, playerResults())
        assert p1results.decode = choice
        _encodedchoice.write(1, playerResults(encode=choice, decode=choice))
        _matchstates.write(playerOne, matchState(join=1, choose=1, reveal=1, settle=0))
    else:
        assert playerTwo = sender_address
        # let (choice) = hash2{hash_ptr=pedersen_ptr}(choice, salt)
        let (p2results) = _encodedchoice.read(2)
        assert p2results.decode = choice
        # assert choice = _encodedchoice.read(1, playerResults.encode)
        _encodedchoice.write(1, playerResults(encode=choice, decode=choice))
        _matchstates.write(playerOne, matchState(join=1, choose=1, reveal=1, settle=0))
    end
    return ()
end
# Function deciding the winner of the contest.

func gameSet{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(x, y) -> (
        x : felt, y : felt):
    [ap] = x - 1; ap++
    [ap] = y / 3; ap++
    ret
end
@external
func settling{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(res : felt):
    # let (state) = _matchstates.read()
    # assert state = matchState.settle
    alloc_locals
    let (sender_address) = get_caller_address()
    let (match_players) = _matchstates.read(sender_address)
    assert match_players.join = 1
    assert match_players.choose = 1
    assert match_players.reveal = 1
    assert match_players.settle = 0

    let (playerOne) = _players.read(1)
    let (playerTwo) = _players.read(2)
    let (p1results) = _encodedchoice.read(1)
    let (p2results) = _encodedchoice.read(2)

    # let (p1choice) = p1results.decode
    # let (p1choice) = _decodedchoice.read(1)
    # let (p2choice) = _encodedchoice.read(2, playerResults.decode)
    if p1results.decode == p2results.decode:
        [ap] = 'draw'
        res = [ap]
        return ()
    else:
        let (local a, local b) = gameSet(x=p1results.decode, y=p2results.decode)
        if a == b:
            [ap] = 'playerOne'
            res = [ap]
            return ()
        else:
            [ap] = 'playerTwo'
            res = [ap]
            return ()
        end
    end
    ret
end
