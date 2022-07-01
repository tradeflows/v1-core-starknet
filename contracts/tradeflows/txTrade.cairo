# SPDX-License-Identifier: MIT
# TradeFlows Trade ERC721 Contracts for Cairo v0.1.0 (traflows/txTrade.cairo)
# Author: @NumbersDeFi

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.library import ERC721

from openzeppelin.token.erc721_enumerable.library import ERC721_Enumerable

from openzeppelin.introspection.ERC165 import ERC165

from openzeppelin.access.ownable import Ownable
from tradeflows.library.trade import Trade, TRADE_trade_count, TRADE_trade_idx, TRADE_fees, TRADE_paid_fees

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address
)

from openzeppelin.security.safemath import SafeUint256

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        owner: felt,
        txDharma_address: felt,
        dao_address: felt
    ):
    ERC721.initializer(name, symbol)
    ERC721_Enumerable.initializer()
    Ownable.initializer(owner)

    Trade.setTxDharma(txDharma_address)
    Trade.setDAO(dao_address)
    return ()
end

#
# Getters
#

@view
func totalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (totalSupply: Uint256):
    let (totalSupply: Uint256) = ERC721_Enumerable.total_supply()
    return (totalSupply)
end

@view
func tokenByIndex{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(index: Uint256) -> (tokenId: Uint256):
    let (tokenId: Uint256) = ERC721_Enumerable.token_by_index(index)
    return (tokenId)
end

@view
func tokenOfOwnerByIndex{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(owner: felt, index: Uint256) -> (tokenId: Uint256):
    let (tokenId: Uint256) = ERC721_Enumerable.token_of_owner_by_index(owner, index)
    return (tokenId)
end

@view
func supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721.balance_of(owner)
    return (balance)
end

@view
func ownerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721.owner_of(tokenId)
    return (owner)
end

@view
func getApproved{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (approved: felt):
    let (approved: felt) = ERC721.get_approved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (isApproved: felt):
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator)
    return (isApproved)
end

@view
func tokenURI{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (tokenURI: felt):
    let (tokenURI: felt) = ERC721.token_uri(tokenId)
    return (tokenURI)
end

#
# Externals
#

@external
func approve{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ERC721.approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721.set_approval_for_all(operator, approved)
    return ()
end

@external
func transferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        from_: felt, 
        to: felt, 
        tokenId: Uint256
    ):
    ERC721_Enumerable.transfer_from(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        from_: felt, 
        to: felt, 
        tokenId: Uint256, 
        data_len: felt,
        data: felt*
    ):
    ERC721_Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    Ownable.assert_only_owner()
    ERC721_Enumerable._mint(to, tokenId)
    return ()
end

@external
func burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256):
    ERC721.assert_only_token_owner(tokenId)
    ERC721_Enumerable._burn(tokenId)
    return ()
end

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, tokenURI: felt):
    Ownable.assert_only_owner()
    ERC721._set_token_uri(tokenId, tokenURI)
    return ()
end

#
# txTrade Custom functionality
#

@view
func isAgreed{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokenId: Uint256
    ) -> (
        agreed: felt,
        timestamp: felt,
        counterpart: felt
    ):

    let (agreed, timestamp, counterpart) = Trade.isAgreed(tokenId)

    return (agreed=agreed, timestamp=timestamp, counterpart=counterpart)
end

@view
func tradeCount{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        counterpart: felt
    ) -> (
        count: felt
    ):

    let (count) = TRADE_trade_count.read(counterpart)
    
    return (count=count)
end

@view
func tradeId{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        counterpart: felt,
        idx: felt
    ) -> (
        tokenId: Uint256
    ):

    let (tokenId) = TRADE_trade_idx.read(counterpart, idx)
    
    return (tokenId=tokenId)
end

@external
func setFee{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        tokenAddress: felt,
        amount: Uint256
    ) -> ():

    TRADE_fees.write(tokenAddress, amount)

    return ()
end

@view
func canAddPayment{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256, 
        tokenAddress: felt
    ) -> (
        success: felt
    ):

    with_attr error_message("fee has not been paid"):
        let (ok)  = TRADE_paid_fees.read(tokenId, tokenAddress)
    end

    with_attr error_message("fee has not been paid"):
        let (agreed, timestamp, counterpart) = Trade.isAgreed(tokenId)

        assert agreed = TRUE
    end

    return (ok)
end


@external
func init{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        counterpart: felt,
        agreementTerms_len: felt,
        agreementTerms: felt*,
        tokens_len: felt,
        tokens: felt*
    ) -> (
        tokenId: Uint256
    ):
    alloc_locals

    let (caller_address)    = get_caller_address()
    let (tokenId)           = Trade.init(counterpart)    
    
    ERC721_Enumerable._mint(caller_address, tokenId)
    Trade.set_agreement_terms(tokenId, agreementTerms_len, agreementTerms)
    Trade.charge_fee(tokenId=tokenId, tokens_len=tokens_len, tokens=tokens)
    
    return (tokenId=tokenId)
end

@view
func agreementTerms{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256
    ) -> (
        agreement_terms_len : felt, 
        agreement_terms : felt*
    ):
    let (agreement_terms_len: felt, agreement_terms: felt*) = Trade.agreement_terms(tokenId)
    return (agreement_terms_len=agreement_terms_len, agreement_terms=agreement_terms)
end

@external
func agree{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        tokenId: Uint256
    ):
    
    Trade.agree(tokenId)
    return ()
end


@external
func rate{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        tokenId: Uint256,
        rating:  Uint256
    ):

    Trade.rate(tokenId, rating)
    return ()
end
