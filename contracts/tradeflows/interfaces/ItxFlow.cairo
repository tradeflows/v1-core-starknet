# SPDX-License-Identifier: MIT
# TradeFlows Flow Interface for Cairo v0.4.0 (tradeflows/interfaces/ItxFlow.cairo)
#
#  _____             _     ______ _                   
# |_   _|           | |    |  ___| |                  
#   | |_ __ __ _  __| | ___| |_  | | _____      _____ 
#   | | '__/ _` |/ _` |/ _ \  _| | |/ _ \ \ /\ / / __|
#   | | | | (_| | (_| |  __/ |   | | (_) \ V  V /\__ \
#   \_/_|  \__,_|\__,_|\___\_|   |_|\___/ \_/\_/ |___/
#
# Author: @NumbersDeFi


%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ItxFlow:
    func increaseTokenId(addrss: felt, tokenId: Uint256, amount : Uint256) -> ():
    end

    func decreaseTokenId(addrss: felt, tokenId: Uint256, amount : Uint256) -> ():
    end

    func lockedTokenId(addrss: felt, tokenId: Uint256) -> (locked_amount: Uint256, block_timestamp: felt):
    end

    func pauseTokenId(addrss: felt, tokenId: Uint256, paused: felt) -> ():
    end

    func transferTokenId(addrss: felt, tokenId: Uint256, addressTo: felt) -> ():
    end
end

