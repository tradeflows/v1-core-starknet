# SPDX-License-Identifier: MIT
# TradeFlows Dharma Interface for Cairo v0.5.0 (tradeflows/interfaces/ItxDharma.cairo)
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
namespace ItxAsset:
    func canAddPayment(tokenId: Uint256, tokenAddress: felt) -> (success: felt):
    end

    func memberWeight(tokenId: Uint256, address: felt) -> (weight: felt, weight_base: felt):
    end

    func baseWeight(tokenId: Uint256) -> (weight_base: felt):
    end

    func getWeights(tokenId: Uint256) -> (wgts_len : felt, wgts : felt*):
    end

    func getAddresses(tokenId: Uint256) -> (addrs_len : felt, addrs : felt*):
    end
end

