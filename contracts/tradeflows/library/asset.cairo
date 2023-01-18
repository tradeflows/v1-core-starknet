# SPDX-License-Identifier: MIT
# TradeFlows Asset library for Cairo v0.5.0 (tradeflows/library/asset.cairo)
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

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_eq,
    uint256_le,
    uint256_lt,
    uint256_check
)

from openzeppelin.token.erc20.library import (
    ERC20_allowances,
    ERC20_balances,

    ERC20
)

from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

from openzeppelin.token.erc721.library import ERC721

from openzeppelin.access.ownable.library import Ownable

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address, 
    get_block_number, 
    get_block_timestamp
)
from starkware.cairo.common.math_cmp import (is_le, is_nn)
from starkware.cairo.common.math import (
    assert_lt,
    unsigned_div_rem,
    assert_nn
)
from starkware.cairo.common.alloc import alloc
from openzeppelin.security.safemath.library import SafeUint256

from tradeflows.interfaces.ItxDharma import ItxDharma

#
# Asset functionality
#

# Event an asset has been initiated
@event
func init_called(tokenId: Uint256, owner: felt, counterpart: felt, block_time: felt):
end

# Event an asset has been agreed
@event
func agree_called(tokenId: Uint256, owner: felt, counterpart: felt, block_time: felt):
end

# Storage of the state of the agreement (agreed = 1 / not agreed = 0)
@storage_var
func agreements_state(tokenId: Uint256) -> (state: felt):
end

# Storage of the agreement counterpart address
@storage_var
func agreements_counterpart(tokenId: Uint256) -> (counterpart: felt):
end

# Storage of the agreement provider address
@storage_var
func agreements_provider(tokenId: Uint256) -> (provider: felt):
end

# Storage of the timestamp of when the agreement was agreed
@storage_var
func agreements_timestamp(tokenId: Uint256) -> (timestamp: felt):
end

# Storage of the timestamp of when the agreement was created
@storage_var
func agreements_creation(tokenId: Uint256) -> (timestamp: felt):
end

# Storage of the number of NFTs minted which is used as a counter
@storage_var
func id_counter() -> (counter: Uint256):
end

# Storage of the address of the Dharma contract
@storage_var
func ASSET_txDharma_address() -> (address: felt):
end

# Storage of the address of the DAO contract
@storage_var
func ASSET_dao_address() -> (address: felt):
end

# Storage of the terms (array) of an agreement
@storage_var
func assets_meta(tokenId : Uint256, index : felt) -> (res : felt):
end

# Storage of the length of the terms array of an agreement 
@storage_var
func assets_meta_len(tokenId : Uint256) -> (res : felt):
end

# Storage fees per token / currency
@storage_var
func ASSET_fees(address: felt) -> (fee: Uint256):
end

# Storage of the state of fees being paid for a specific asset
@storage_var
func ASSET_paid_fees(tokenId: Uint256, address: felt) -> (success: felt):
end

# Storage of the counter of the number of assets per address
@storage_var
func ASSET_asset_count(address: felt) -> (count: felt):
end

# Storage of the tokenId given an address and an index
@storage_var
func ASSET_asset_idx(address: felt, idx: felt) -> (tokenId: Uint256):
end

# Storage of the member addresses (array) of an agreement
@storage_var
func ASSET_addresses(tokenId : Uint256, index : felt) -> (res : felt):
end

# Storage of the member weights (array) of an agreement
@storage_var
func ASSET_weights(tokenId : Uint256, index : felt) -> (res : felt):
end

# Storage of the member length of the terms array of an agreement 
@storage_var
func ASSET_weights_len(tokenId : Uint256) -> (res : felt):
end

# Storage of the base_weight
@storage_var
func ASSET_base_weight(tokenId : Uint256) -> (res : felt):
end

# Storage of the member weights (array) of an agreement
@storage_var
func ASSET_sub_tokens(tokenId : Uint256, index : felt) -> (res : Uint256):
end

# Storage of the member length of the terms array of an agreement 
@storage_var
func ASSET_sub_tokens_len(tokenId : Uint256) -> (res : felt):
end

# Storage of the member weights (array) of an agreement
@storage_var
func ASSET_sub_types(tokenId : Uint256, index : felt) -> (res : felt):
end

namespace Asset:

    # init a asset
    func init{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            counterpart: felt,
            members_len: felt,
            members: felt*,
            weights_len: felt,
            weights: felt*
        ) -> (
            tokenId: Uint256
        ):
        alloc_locals
        
        let (caller_address)        = get_caller_address()

        let (tokenId : Uint256)     = id_counter.read()
        let (next_tokenId)          = SafeUint256.add(tokenId, Uint256(1,0))
        id_counter.write(next_tokenId)

        let (block_timestamp)       = get_block_timestamp()

        agreements_provider.write(tokenId, caller_address)
        agreements_counterpart.write(tokenId, counterpart)
        agreements_creation.write(tokenId, block_timestamp)

        let (t_count)               = ASSET_asset_count.read(counterpart)
        
        ASSET_asset_idx.write(counterpart, t_count, tokenId)
        let new_count               = t_count + 1
        ASSET_asset_count.write(counterpart, new_count)

        with_attr error_message("members_len must equal to weights_len"):
            assert members_len = weights_len
        end

        if members_len == 0:
            let (local addrs_value) = alloc()
            assert [addrs_value]    = caller_address
            let (local wgts_value)  = alloc()
            assert [wgts_value]     = 1
            setWeights(tokenId, 1, addrs_value, 1, wgts_value)
            ASSET_base_weight.write(tokenId, 1)
        else:
            let (_wgts)             = sum(weights_len, weights)

            setWeights(tokenId, members_len, members, weights_len, weights)
            ASSET_base_weight.write(tokenId, _wgts)
        end

        init_called.emit(tokenId, caller_address, counterpart, block_timestamp)
        
        return (tokenId=tokenId)
    end

    func sum{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            weights_len: felt,
            weights: felt*
        ) -> (
            res: felt
        ):
        
        if weights_len == 0:
            return (0)
        end

        let wgt   = [weights]
        let (res) = sum(weights_len-1,weights+1)
        return (res=wgt+res)
    end

    # init agree to a asset
    func agree{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            tokenId: Uint256
        ):

        # ensure valid uint256
        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        let (counterpart)       = agreements_counterpart.read(tokenId)
        let (caller_address)    = get_caller_address()

        with_attr error_message("only the tokenId counterpart can agree"):
            assert counterpart = caller_address
        end
        
        let(state) = agreements_state.read(tokenId)

        with_attr error_message("deal is already agreed"):
            assert state = FALSE
        end

        let (block_timestamp)   = get_block_timestamp()

        agreements_state.write(tokenId, TRUE)
        agreements_timestamp.write(tokenId, block_timestamp)

        let (owner)             = agreements_provider.read(tokenId)
        agree_called.emit(tokenId, owner, counterpart, block_timestamp)
        
        return ()
    end

    # check if asset has been agreed
    func isAgreed{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            tokenId: Uint256
        ) -> (
            agreed: felt,
            timestamp: felt,
            counterpart_address: felt
        ):

        # ensure valid uint256
        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end
        
        let (agreed)        = agreements_state.read(tokenId)
        let (timestamp)     = agreements_timestamp.read(tokenId)
        let (counterpart)   = agreements_counterpart.read(tokenId)
        
        return (agreed=agreed, timestamp=timestamp, counterpart_address=counterpart)
    end

    # set Dharma address
    func setTxDharma{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            addrss: felt
        ) -> ():
        
        ASSET_txDharma_address.write(addrss)
        return()
    end

    # get Dharma address
    func getTxDharma{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }() ->
        (
            address: felt
        ):
        
        let (addrss) = ASSET_txDharma_address.read()
        return(address=addrss)
    end

    # set DAO address
    func setDAO{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            addrss: felt
        ) -> ():
        
        ASSET_dao_address.write(addrss)
        return()
    end

    # get DAO address
    func getDAO{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }() ->
        (
            address: felt
        ):
        
        let (addrss) = ASSET_dao_address.read()
        return(address=addrss)
    end

    # get base weight
    func getBaseWeight{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            tokenId: Uint256
        ) ->
        (
            weight: felt
        ):
        
        let (weight) = ASSET_base_weight.read(tokenId)
        return(weight=weight)
    end

    # rate a given address and asset (tokenId)
    func rate{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            tokenId: Uint256,
            amount:  Uint256    
        ) ->
        ():

        alloc_locals

        # ensure valid uint256
        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end
        with_attr error_message("amount is not a valid Uint256"):
            uint256_check(amount)
        end

        let(state) = agreements_state.read(tokenId)

        with_attr error_message("deal is not agreed"):
            assert state = TRUE
        end

        let (caller_address)    = get_caller_address()
        let (provider)          = agreements_provider.read(tokenId)
        let (counterpart)       = agreements_counterpart.read(tokenId)

        let (txDharma)          = ASSET_txDharma_address.read()

        let (negAmount)         = uint256_le(amount, Uint256(0, 0))

        if caller_address == provider:
            if negAmount == TRUE:
                ItxDharma.burn(contract_address=txDharma, to=counterpart, amount=amount)
            else:
                ItxDharma.mint(contract_address=txDharma, to=counterpart, amount=amount)
            end

            return ()
        end

        if caller_address == counterpart:
            if negAmount == TRUE:
                ItxDharma.burn(contract_address=txDharma, to=provider, amount=amount)
            else:
                ItxDharma.mint(contract_address=txDharma, to=provider, amount=amount)
            end

            return ()
        end

        with_attr error_message("Unknown caller"):
            assert TRUE = FALSE
        end

        return ()
    end

    # get meta
    func assetMeta{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256
        ) -> (
            agreement_terms_len : felt, 
            agreement_terms : felt*
        ):
        alloc_locals

        # ensure valid uint256
        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        # ensure token with token_id exists
        let (exists) = ERC721._exists(tokenId)
        with_attr error_message("nonexistent token"):
            assert exists = TRUE
        end

        let (local agreement_terms_len) = assets_meta_len.read(tokenId)

        let (local agreement_terms_value) = alloc()

        _asset_meta(tokenId, agreement_terms_len, agreement_terms_value)

        return (agreement_terms_len, agreement_terms_value)
    end

    # set meta
    func setMeta{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            agreement_terms_len : felt, 
            agreement_terms : felt*
        ):

        uint256_check(tokenId)
        let (exists) = ERC721._exists(tokenId)
        with_attr error_message("nonexistent token"):
            assert exists = TRUE
        end

        _set_asset_meta(tokenId, agreement_terms_len, agreement_terms)
        assets_meta_len.write(tokenId, agreement_terms_len)
        return ()
    end

    # reset agreement terms
    func resetMeta{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256
        ):

        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        setMeta(tokenId, 0, &[0])
        return ()
    end

    # helper: get agreement terms
    func _asset_meta{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            agreement_terms_len : felt, 
            agreement_terms : felt*
        ):

        if agreement_terms_len == 0:
            return ()
        end

        let (agreement_terms_value_at_index)    = assets_meta.read(tokenId, agreement_terms_len)
        assert [agreement_terms]                = agreement_terms_value_at_index
        _asset_meta(tokenId, agreement_terms_len - 1, agreement_terms + 1)
        return ()
    end

    # helper: set agreement terms
    func _set_asset_meta{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            agreement_terms_len : felt, 
            agreement_terms : felt*
        ):

        if agreement_terms_len == 0:
            return ()
        end

        assets_meta.write(tokenId, agreement_terms_len, [agreement_terms])
        _set_asset_meta(tokenId, agreement_terms_len - 1, agreement_terms + 1)
        return ()
    end

    # charge fees
    func chargeFee{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            tokenId: Uint256,
            tokens_len: felt,
            tokens: felt*,
        ) -> ():
        alloc_locals

        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        if tokens_len == 0:
            return ()
        end

        let (local caller_address)  = get_caller_address()
        
        with_attr error_message("no token in array"):
            let tok                 = [tokens]
        end

        with_attr error_message("fee not set"):
            let (amount)            = ASSET_fees.read(tok)
        end

        with_attr error_message("amount must be greater than 0"):
            let (ok)                = uint256_lt(Uint256(0,0),amount)
            assert ok = TRUE
        end

        let (dao)                   = ASSET_dao_address.read()
        
        IERC20.transferFrom(contract_address=tok, sender=caller_address, recipient=dao, amount=amount)

        ASSET_paid_fees.write(tokenId, tok, 1)
        
        chargeFee(tokenId=tokenId, tokens_len=tokens_len-1,tokens=tokens+1)

        return ()
    end

    #
    # Member Weights / Payment split
    #

    # set weights
    func setWeights{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            addrss_len : felt, 
            addrss : felt*,
            wgts_len : felt, 
            wgts : felt*
        ):

        uint256_check(tokenId)
        
        with_attr error_message("address length must equal to weights length"):
            assert addrss_len = wgts_len
        end

        _set_weights(tokenId, wgts_len, wgts)
        _set_addresses(tokenId, wgts_len, addrss)
        ASSET_weights_len.write(tokenId, wgts_len)
        return ()
    end

    # get weights
    func getWeights{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256
        ) -> (
            wgts_len : felt, 
            wgts : felt*
        ):
        alloc_locals

        # ensure valid uint256
        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        # ensure token with token_id exists
        let (exists) = ERC721._exists(tokenId)
        with_attr error_message("nonexistent token"):
            assert exists = TRUE
        end

        let (local wgts_len)    = ASSET_weights_len.read(tokenId)
        let (local wgts_value)  = alloc()

        _weights(tokenId, wgts_len, wgts_value)

        return (wgts_len, wgts_value)
    end

    # get addresses
    func getAddresses{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256
        ) -> (
            addrs_len : felt, 
            addrs : felt*
        ):
        alloc_locals

        # ensure valid uint256
        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        # ensure token with token_id exists
        let (exists) = ERC721._exists(tokenId)
        with_attr error_message("nonexistent token"):
            assert exists = TRUE
        end

        let (local addrs_len) = ASSET_weights_len.read(tokenId)
        let (local addrs_value) = alloc()

        _addresses(tokenId, addrs_len, addrs_value)

        return (addrs_len, addrs_value)
    end

    # get weight
    func getWeight{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256,
            addrs: felt
        ) -> (
            weight : felt,
            weight_base: felt
        ):
        alloc_locals

        # ensure valid uint256
        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        # ensure token with token_id exists
        let (exists)                    = ERC721._exists(tokenId)
        with_attr error_message("nonexistent token"):
            assert exists = TRUE
        end

        let (addrss_len, addrss)        = getAddresses(tokenId)
        let (wgts_len, wgts)            = getWeights(tokenId)

        with_attr error_message("address length is not equal to weights length"):
            assert wgts_len = addrss_len
        end

        let (weight)                    = _get_weight(addrs, wgts_len, wgts, addrss)
        let (_weight_base)              = ASSET_base_weight.read(tokenId)

        with_attr error_message("weight cannot be 0"):
            assert_nn(weight)
        end
        
        return (weight=weight, weight_base=_weight_base)
    end

    # helper: get weights
    func _get_weight{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            address: felt,
            wgts_len: felt,
            wgts: felt*,
            addrss: felt*
            
        ) -> (
            weight : felt
        ):
        if wgts_len == 0:
            return (weight=0)
        end

        let _addrss = [addrss]
        let _wgt    = [wgts]
        
        if address == _addrss:
            return (weight=_wgt)
        else:
            let (weight) = _get_weight(address, wgts_len-1, wgts+1, addrss+1)
            return (weight=weight)
        end
    end

    # helper: set weights
    func _set_weights{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            wgts_len : felt, 
            wgts : felt*
        ):

        if wgts_len == 0:
            return ()
        end

        ASSET_weights.write(tokenId, wgts_len, [wgts])
        _set_weights(tokenId, wgts_len - 1, wgts + 1)
        return ()
    end

    # helper: set addresses
    func _set_addresses{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            addrss_len : felt, 
            addrss : felt*
        ):

        if addrss_len == 0:
            return ()
        end

        ASSET_addresses.write(tokenId, addrss_len, [addrss])
        _set_addresses(tokenId, addrss_len - 1, addrss + 1)
        return ()
    end

    # helper: get weights
    func _weights{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            wgts_len : felt, 
            wgts : felt*
        ):

        if wgts_len == 0:
            return ()
        end

        let (wgts_value_at_index) = ASSET_weights.read(tokenId, wgts_len)
        assert [wgts] = wgts_value_at_index
        _weights(tokenId, wgts_len - 1, wgts + 1)
        return ()
    end

    # helper: get addresses
    func _addresses{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            addrss_len : felt, 
            addrss : felt*
        ):

        if addrss_len == 0:
            return ()
        end

        let (addrss_value_at_index) = ASSET_addresses.read(tokenId, addrss_len)
        assert [addrss] = addrss_value_at_index
        _addresses(tokenId, addrss_len - 1, addrss + 1)
        return ()
    end

    # reset weights
    func resetWeights{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256
        ):

        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        setWeights(tokenId, 0, &[0], 0, &[0])
        return ()
    end

    #
    # Composability
    #

    # get sub tokens
    func subTokens{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256
        ) -> (
            subTokens_len : felt, 
            subTokens : Uint256*
        ):
        alloc_locals

        # ensure valid uint256
        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        # ensure token with token_id exists
        let (exists) = ERC721._exists(tokenId)
        with_attr error_message("nonexistent token"):
            assert exists = TRUE
        end

        let (local sub_tokens_len)              = ASSET_sub_tokens_len.read(tokenId)

        let (local sub_tokens_value : Uint256*) = alloc()

        _sub_tokens(tokenId, sub_tokens_len, sub_tokens_value)

        return (sub_tokens_len, sub_tokens_value)
    end

    # get sub types
    func subTypes{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256
        ) -> (
            subTypes_len : felt, 
            subTypes : felt*
        ):
        alloc_locals

        # ensure valid uint256
        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        # ensure token with token_id exists
        let (exists) = ERC721._exists(tokenId)
        with_attr error_message("nonexistent token"):
            assert exists = TRUE
        end

        let (local sub_tokens_len) = ASSET_sub_tokens_len.read(tokenId)

        let (local sub_types_value) = alloc()
        _sub_types(tokenId, sub_tokens_len, sub_types_value)

        return (sub_tokens_len, sub_types_value)
    end

    # reset weights
    func deComposeSubTokens{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256
        ):

        alloc_locals

        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        let (_sub_tokens_len, _sub_tokens) = subTokens(tokenId)

        let (local sub_tokens_value : Uint256*) = alloc()

        _reset_sub_tokens(tokenId, _sub_tokens_len, _sub_tokens)
        _set_sub_tokens(tokenId, 0, sub_tokens_value)
        _set_sub_types(tokenId, 0, &[0])
        ASSET_sub_tokens_len.write(tokenId, 0)
        return ()
    end

    # set sub tokens
    func composeSubTokens{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            subTypes_len : felt, 
            subTypes : felt*,
            subTokenIds_len : felt, 
            subTokenIds : Uint256*
        ):

        uint256_check(tokenId)
        
        with_attr error_message("address length must equal to weights length"):
            assert subTypes_len = subTokenIds_len
        end

        deComposeSubTokens(tokenId)

        _set_sub_types(tokenId, subTypes_len, subTypes)
        _set_sub_tokens(tokenId, subTokenIds_len, subTokenIds)
        ASSET_sub_tokens_len.write(tokenId, subTokenIds_len)
        return ()
    end

    # helper: set sub tokens
    func _set_sub_tokens{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            sub_tokens_len : felt, 
            sub_tokens : Uint256*
        ):

        if sub_tokens_len == 0:
            return ()
        end

        let (caller_address)   = get_caller_address()
        let (contract_address) = get_contract_address()

        ERC721.transfer_from(caller_address, contract_address, [sub_tokens])

        ASSET_sub_tokens.write(tokenId, sub_tokens_len, [sub_tokens])
        _set_sub_tokens(tokenId, sub_tokens_len - 1, sub_tokens + 1)
        return ()
    end

    # helper: set sub tokens
    func _reset_sub_tokens{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            sub_tokens_len : felt, 
            sub_tokens : Uint256*
        ):

        alloc_locals

        if sub_tokens_len == 0:
            return ()
        end

        let (caller_address)   = get_caller_address()
        let (contract_address) = get_contract_address()

        ERC721._approve(caller_address, [sub_tokens])
        ERC721.transfer_from(contract_address, caller_address, [sub_tokens])

        _reset_sub_tokens(tokenId, sub_tokens_len - 1, sub_tokens + 1)
        return ()
    end

    # helper: get sub tokens
    func _sub_tokens{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            sub_tokens_len : felt, 
            sub_tokens : Uint256*
        ):

        if sub_tokens_len == 0:
            return ()
        end

        let (sub_tokens_value_at_index) = ASSET_sub_tokens.read(tokenId, sub_tokens_len)
        assert [sub_tokens] = sub_tokens_value_at_index
        _sub_tokens(tokenId, sub_tokens_len - 1, sub_tokens + 1)
        return ()
    end

    # helper: set sub types
    func _set_sub_types{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            sub_types_len : felt, 
            sub_types : felt*
        ):

        if sub_types_len == 0:
            return ()
        end

        ASSET_sub_types.write(tokenId, sub_types_len, [sub_types])
        _set_sub_types(tokenId, sub_types_len - 1, sub_types + 1)
        return ()
    end

    # helper: get sub types
    func _sub_types{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256, 
            sub_types_len : felt, 
            sub_types : felt*
        ):

        if sub_types_len == 0:
            return ()
        end

        let (sub_types_value_at_index) = ASSET_sub_types.read(tokenId, sub_types_len)
        assert [sub_types] = sub_types_value_at_index
        _sub_types(tokenId, sub_types_len - 1, sub_types + 1)
        return ()
    end
end