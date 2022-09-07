
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from src.rockpaperscissors import register_players, player_info,get_TotalGames, PlayerInfo, joining, matchState, _matchstates, submitting, revealing, get_matchResults, playerResults, set_tling, _matchrecord, _totalGames, matchStore, matches

@contract_interface
namespace PlayingContract:
    func joining(play : felt):
    end

    func submitting(choose : felt):
    end
     func get_TotalGames() -> (mat: matches):
    end


    func revealing():
    end

    func set_tling():
    end
    func get_state() -> (state: matchState):
    end

    func get_player_Results() -> (results: playerResults):
    end

    func get_matchResults(id : felt) -> (results: matchStore):
    end


    func get_playerInfo(user: felt) -> (playerstate: PlayerInfo):
    end
end
 
@external
func test_settling{
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
    PlayingContract.submitting(playing_contract_address, 1)
    %{ stop_prank_callback() %}
    
    %{ stop_prank_callback = start_prank(222, target_contract_address=ids.playing_contract_address) %} 
    PlayingContract.joining(playing_contract_address, 1)
    PlayingContract.submitting(playing_contract_address, 3)
    %{ stop_prank_callback() %}
    
    # Check results as a third party
    %{ stop_prank_callback = start_prank(444, target_contract_address=ids.playing_contract_address) %} 
    PlayingContract.revealing(playing_contract_address)
    PlayingContract.set_tling(playing_contract_address)
    let (state) = PlayingContract.get_state(playing_contract_address)
    let (player1state) = PlayingContract.get_playerInfo(playing_contract_address, 111)
    let (player2state) = PlayingContract.get_playerInfo(playing_contract_address, 222)
    let (players_results) = PlayingContract.get_player_Results(playing_contract_address)
    let (games) = PlayingContract.get_TotalGames((playing_contract_address))

    let (match_results) = PlayingContract.get_matchResults(playing_contract_address, games.gameId)
    assert state.reveal = 1
    assert player1state.revealed = 1
    assert player2state.revealed = 1
    assert players_results.player0ne = player1state.choice
    assert players_results.playerTwo = player2state.choice
    
    assert match_results.champ = 111
    assert match_results.loser = 222
    assert match_results.drawn = 0
    return ()
end