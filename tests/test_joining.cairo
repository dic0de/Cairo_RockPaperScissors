
%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc

from src.rockpaperscissors import register_players, player_info, PlayerInfo, joining, matchState, _matchstates
@external
func __setup__{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals
    let (local addresses: felt*) = alloc()
    let registered_player = 111 
    assert addresses[0] = registered_player
    register_players(1, addresses)
    %{ 
       context.registered_player = ids.registered_player # Store registered voter in context  
    %}
    
    return ()
end
 
@external
func test_joining{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals
    let (local addresses: felt*) = alloc()
    assert addresses[0] = 111
    register_players(1, addresses)
    %{ start_prank(111) %}
    joining(1)
    # Check voting state
    let (state) = _matchstates.read()
    assert state.join = 1
    assert state.choose = 0
    # Check voter info
    let (player) = player_info.read(111)
    assert player.played = 1
    return ()
end
 