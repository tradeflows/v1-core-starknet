# SPDX-License-Identifier: MIT
# TradeFlows Asset ERC721 Contracts for Cairo v0.2.0 (traflows/txAsset.cairo)
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

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE

from openzeppelin.token.erc721_enumerable.library import ERC721_Enumerable
from openzeppelin.security.reentrancyguard import ReentrancyGuard
from openzeppelin.security.safemath import SafeUint256
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.ERC165 import ERC165
from openzeppelin.access.ownable import Ownable

from tradeflows.library.asset import Asset, ASSET_asset_count, ASSET_asset_idx, ASSET_fees, ASSET_paid_fees

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

    Asset.setTxDharma(txDharma_address)
    Asset.setDAO(dao_address)
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
    ReentrancyGuard._start()
    ERC721.approve(to, tokenId)
    ReentrancyGuard._end()
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(operator: felt, approved: felt):
    ReentrancyGuard._start()
    ERC721.set_approval_for_all(operator, approved)
    ReentrancyGuard._end()
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
    ReentrancyGuard._start()
    ERC721_Enumerable.transfer_from(from_, to, tokenId)
    ReentrancyGuard._end()
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
    ReentrancyGuard._start()
    ERC721_Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data)
    ReentrancyGuard._end()
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ReentrancyGuard._start()
    Ownable.assert_only_owner()
    ERC721_Enumerable._mint(to, tokenId)
    ReentrancyGuard._end()
    return ()
end

@external
func burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256):
    ReentrancyGuard._start()
    ERC721.assert_only_token_owner(tokenId)
    ERC721_Enumerable._burn(tokenId)
    ReentrancyGuard._end()
    return ()
end

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, tokenURI: felt):
    ReentrancyGuard._start()
    Ownable.assert_only_owner()
    ERC721._set_token_uri(tokenId, tokenURI)
    ReentrancyGuard._end()
    return ()
end

#
# txTrade Custom functionality
#

#
# Getters
#

# check if asset has been agreed
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

    let (agreed, timestamp, counterpart) = Asset.isAgreed(tokenId)

    return (agreed=agreed, timestamp=timestamp, counterpart=counterpart)
end

# number of asset of an address
@view
func assetCount{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        counterpart: felt
    ) -> (
        count: felt
    ):

    let (count) = ASSET_asset_count.read(counterpart)
    
    return (count=count)
end

# get tokenId for a specific counterpart and index
@view
func assetId{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        counterpart: felt,
        idx: felt
    ) -> (
        tokenId: Uint256
    ):

    let (tokenId) = ASSET_asset_idx.read(counterpart, idx)
    
    return (tokenId=tokenId)
end

# check if a payment flow can be added to the asset
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
        let (ok)  = ASSET_paid_fees.read(tokenId, tokenAddress)
    end

    with_attr error_message("fee has not been paid"):
        let (agreed, timestamp, counterpart) = Asset.isAgreed(tokenId)

        assert agreed = TRUE
    end

    return (ok)
end

# check if a payment flow can be added to the asset
@view
func memberWeight{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256, 
        address: felt
    ) -> (
        weight: felt,
        weight_base: felt
    ):
    
    let (weight, weight_base) = Asset.getWeight(tokenId=tokenId, address=address)
    return (weight=weight, weight_base=weight_base)
end

@view
func baseWeight{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256
    ) -> (
        weight: felt
    ):
    
    let (weight) = Asset.getBaseWeight(tokenId)
    return (weight=weight)
end

@view
func getWeights{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256
    ) -> (
        wgts_len : felt, 
        wgts : felt*
    ):
    let (wgts_len : felt, wgts : felt*) = Asset.getWeights(tokenId)

    return (wgts_len, wgts)
end

@view
func getAddresses{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256
    ) -> (
        addrs_len : felt, 
        addrs : felt*
    ):
    let (addrs_len : felt, addrs : felt*) = Asset.getAddresses(tokenId)

    return (addrs_len, addrs)
end

# get the agreement terms
@view
func assetMeta{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256
    ) -> (
        agreement_terms_len : felt, 
        agreement_terms : felt*
    ):
    let (agreement_terms_len: felt, agreement_terms: felt*) = Asset.assetMeta(tokenId)
    return (agreement_terms_len=agreement_terms_len, agreement_terms=agreement_terms)
end

#
# Externals
#

# initialize an asset
@external
func init{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        counterpart: felt,
        meta_len: felt,
        meta: felt*,
        tokens_len: felt,
        tokens: felt*,
        members_len: felt,
        members: felt*,
        weights_len: felt,
        weights: felt*
    ) -> (
        tokenId: Uint256
    ):
    alloc_locals
    ReentrancyGuard._start()
    let (caller_address)    = get_caller_address()
    let (tokenId)           = Asset.init(counterpart, members_len, members, weights_len, weights)    
    
    ERC721_Enumerable._mint(caller_address, tokenId)
    Asset.setMeta(tokenId, meta_len, meta)
    Asset.chargeFee(tokenId=tokenId, tokens_len=tokens_len, tokens=tokens)
    ReentrancyGuard._end()
    return (tokenId=tokenId)
end

# agree to an asset
@external
func agree{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        tokenId: Uint256
    ):
    ReentrancyGuard._start()
    Asset.agree(tokenId)
    ReentrancyGuard._end()
    return ()
end

# rate a given address and asset (tokenId)
@external
func rate{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        tokenId: Uint256,
        rating:  Uint256
    ):
    ReentrancyGuard._start()
    Asset.rate(tokenId, rating)
    ReentrancyGuard._end()
    return ()
end

# set the fee for a given token
@external
func setFee{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        tokenAddress: felt,
        amount: Uint256
    ) -> ():
    ReentrancyGuard._start()
    ASSET_fees.write(tokenAddress, amount)
    ReentrancyGuard._end()
    return ()
end
