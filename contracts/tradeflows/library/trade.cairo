# SPDX-License-Identifier: MIT
# TradeFlows Trade library for Cairo v0.1.0 (traflows/library/trade.cairo)
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

from openzeppelin.access.ownable import Ownable

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
from openzeppelin.security.safemath import SafeUint256

from tradeflows.interfaces.ItxDharma import ItxDharma

#
# Trade functionality
#

# Event a trade has been initiated
@event
func init_called(tokenId: Uint256, owner: felt, counterpart: felt):
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

# Storage of the number of NFTs minted which is used as a counter
@storage_var
func id_counter() -> (counter: Uint256):
end

# Storage of the address of the Dharma contract
@storage_var
func txDharma_address() -> (address: felt):
end

# Storage of the address of the DAO contract
@storage_var
func dao_address() -> (address: felt):
end

# Storage of the terms (array) of an agreement
@storage_var
func agreements_terms(tokenId : Uint256, index : felt) -> (res : felt):
end

# Storage of the length of the terms array of an agreement 
@storage_var
func agreements_terms_len(tokenId : Uint256) -> (res : felt):
end

# Storage fees per token / currency
@storage_var
func TRADE_fees(address: felt) -> (fee: Uint256):
end

# Storage of the state of fees being paid for a specific trade
@storage_var
func TRADE_paid_fees(tokenId: Uint256, address: felt) -> (success: felt):
end

# Storage of the counter of the number of trades per address
@storage_var
func TRADE_trade_count(address: felt) -> (count: felt):
end

# Storage of the tokenId given an address and an index
@storage_var
func TRADE_trade_idx(address: felt, idx: felt) -> (tokenId: Uint256):
end

# Storage of the member addresses (array) of an agreement
@storage_var
func addresses(tokenId : Uint256, index : felt) -> (res : felt):
end

# Storage of the member weights (array) of an agreement
@storage_var
func weights(tokenId : Uint256, index : felt) -> (res : felt):
end

# Storage of the member length of the terms array of an agreement 
@storage_var
func weights_len(tokenId : Uint256) -> (res : felt):
end

const _weight_base = 1000000000000

namespace Trade:

    # init a trade
    func init{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            counterpart: felt
        ) -> (
            tokenId: Uint256
        ):
        alloc_locals

        let (caller_address)   = get_caller_address()

        let (tokenId : Uint256)= id_counter.read()
        let (next_tokenId)     = SafeUint256.add(tokenId, Uint256(1,0))
        id_counter.write(next_tokenId)

        agreements_provider.write(tokenId, caller_address)
        agreements_counterpart.write(tokenId, counterpart)

        let (t_count)          = TRADE_trade_count.read(counterpart)
        
        TRADE_trade_idx.write(counterpart, t_count, tokenId)
        let new_count          = t_count + 1
        TRADE_trade_count.write(counterpart, new_count)

        let (local addrs_value) = alloc()
        assert [addrs_value] = caller_address
        let (local wgts_value) = alloc()
        assert [wgts_value] = _weight_base
        setWeights(tokenId, 1, addrs_value, 1, wgts_value)
        
        init_called.emit(tokenId, caller_address, counterpart)
        
        return (tokenId=tokenId)
    end

    # init agree to a trade
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
        
        return ()
    end

    # check if trade has been agreed
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
        
        let (agreed) = agreements_state.read(tokenId)
        let (timestamp) = agreements_timestamp.read(tokenId)
        let (counterpart) = agreements_counterpart.read(tokenId)
        
        return (agreed=agreed, timestamp=timestamp, counterpart_address=counterpart)
    end

    # set Dharma address
    func setTxDharma{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            address: felt
        ) -> ():
        
        txDharma_address.write(address)
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
        
        let (address) = txDharma_address.read()
        return(address=address)
    end

    # set DAO address
    func setDAO{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            address: felt
        ) -> ():
        
        dao_address.write(address)
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
        
        let (address) = dao_address.read()
        return(address=address)
    end

    # rate a given address and trade (tokenId)
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

        let (txDharma)          = txDharma_address.read()

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

    # get agreement terms
    func agreementTerms{
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

        let (local agreement_terms_len) = agreements_terms_len.read(tokenId)

        let (local agreement_terms_value) = alloc()

        _agreement_terms(tokenId, agreement_terms_len, agreement_terms_value)

        return (agreement_terms_len, agreement_terms_value)
    end

    # set agreement terms
    func setAgreementTerms{
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

        _set_terms(tokenId, agreement_terms_len, agreement_terms)
        agreements_terms_len.write(tokenId, agreement_terms_len)
        return ()
    end

    # reset agreement terms
    func resetAgreementsTerms{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256
        ):

        with_attr error_message("tokenId is not a valid Uint256"):
            uint256_check(tokenId)
        end

        setAgreementTerms(tokenId, 0, &[0])
        return ()
    end

    # helper: get agreement terms
    func _agreement_terms{
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

        let (agreement_terms_value_at_index) = agreements_terms.read(tokenId, agreement_terms_len)
        assert [agreement_terms] = agreement_terms_value_at_index
        _agreement_terms(tokenId, agreement_terms_len - 1, agreement_terms + 1)
        return ()
    end

    # helper: set agreement terms
    func _set_terms{
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

        agreements_terms.write(tokenId, agreement_terms_len, [agreement_terms])
        _set_terms(tokenId, agreement_terms_len - 1, agreement_terms + 1)
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
        let (contract_address)      = get_contract_address()
        
        with_attr error_message("no token in array"):
            let tok                 = [tokens]
        end

        with_attr error_message("fee not set"):
            let (amount)            = TRADE_fees.read(tok)
        end

        with_attr error_message("amount must be greater than 0"):
            let (ok)                = uint256_lt(Uint256(0,0),amount)
            assert ok = TRUE
        end

        let (dao)                   = dao_address.read()
        
        IERC20.transferFrom(contract_address=tok, sender=caller_address, recipient=dao, amount=amount)

        TRADE_paid_fees.write(tokenId, tok, 1)
        
        chargeFee(tokenId=tokenId, tokens_len=tokens_len-1,tokens=tokens+1)

        return ()
    end

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
        weights_len.write(tokenId, wgts_len)
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

        let (local wgts_len) = weights_len.read(tokenId)

        let (local wgts_value) = alloc()

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

        let (local addrs_len) = weights_len.read(tokenId)

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
            address: felt
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


        let (weight)                    = _get_weight(address, wgts_len, wgts, addrss)

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

        weights.write(tokenId, wgts_len, [wgts])
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

        addresses.write(tokenId, addrss_len, [addrss])
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

        let (wgts_value_at_index) = weights.read(tokenId, wgts_len)
        assert [wgts] = wgts_value_at_index
        _weights(tokenId, wgts_len - 1, wgts + 1)
        return ()
    end

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

        let (addrss_value_at_index) = addresses.read(tokenId, addrss_len)
        assert [addrss] = addrss_value_at_index
        _addresses(tokenId, addrss_len - 1, addrss + 1)
        return ()
    end
end