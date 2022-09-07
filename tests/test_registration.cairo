%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from src.rockpaperscissors import register_players, player_info
 
@external
func test_register_players{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals
    let (local addresses: felt*) = alloc()
    assert addresses[0] = 111
    assert addresses[1] = 222
    assert addresses[2] = 333
    register_players(3, addresses)
    
    # Check registered voters
    let (player) = player_info.read(111)
    assert player.allowed = 1
     
    let (player) = player_info.read(222)
    assert player.allowed = 1
    
    let (player) = player_info.read(333)
    assert player.allowed = 1
    
    # Check example non-registered voter 
    let (player) = player_info.read(4231421)
    assert player.allowed = 0
    return ()
end