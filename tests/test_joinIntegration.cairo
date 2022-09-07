
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from src.rockpaperscissors import register_players, player_info, PlayerInfo, joining, matchState, _matchstates

@contract_interface
namespace PlayingContract:
    func joining(vote : felt):
    end
    
    func get_state() -> (state: matchState):
    end
end
 
@external
func test_multiplejoining{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals
    # Deploy the contract
    local playing_contract_address
    %{ ids.playing_contract_address = deploy_contract('./src/rockpaperscissors.cairo', {"addresses": [111, 222]}).contract_address %}  
    
    # Let everybody play
    %{ stop_prank_callback = start_prank(111, target_contract_address=ids.playing_contract_address) %} 
    PlayingContract.joining(playing_contract_address, 1)
    %{ stop_prank_callback() %}
    
    %{ stop_prank_callback = start_prank(222, target_contract_address=ids.playing_contract_address) %} 
    PlayingContract.joining(playing_contract_address, 1)
    %{ stop_prank_callback() %}
    
    # Check results as a third party
    %{ stop_prank_callback = start_prank(444, target_contract_address=ids.playing_contract_address) %} 
    let (state) = PlayingContract.get_state(playing_contract_address)
    assert state.join = 2
    return ()
end