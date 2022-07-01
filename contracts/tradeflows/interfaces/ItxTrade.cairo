# SPDX-License-Identifier: MIT
# TradeFlows Dharma Interface for Cairo v0.1.0 (traflows/interfaces/ItxDharma.cairo)
# Author: @NumbersDeFi

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ItxTrade:
    func canAddPayment(tokenId: Uint256, tokenAddress: felt) -> (success: felt):
    end
end

