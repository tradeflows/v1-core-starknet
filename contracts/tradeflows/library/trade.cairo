# SPDX-License-Identifier: MIT
# TradeFlows Trade library for Cairo v0.1.0 (traflows/library/trade.cairo)
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

@event
func init_called(tokenId: Uint256, owner: felt, counterpart: felt):
end

@storage_var
func agreements_state(tokenId: Uint256) -> (state: felt):
end

@storage_var
func agreements_counterpart(tokenId: Uint256) -> (counterpart: felt):
end

@storage_var
func agreements_provider(tokenId: Uint256) -> (provider: felt):
end

@storage_var
func agreements_timestamp(tokenId: Uint256) -> (timestamp: felt):
end

@storage_var
func id_counter() -> (counter: Uint256):
end

@storage_var
func txDharma_address() -> (address: felt):
end

@storage_var
func dao_address() -> (address: felt):
end


@storage_var
func agreements_terms(tokenId : Uint256, index : felt) -> (res : felt):
end

@storage_var
func agreements_terms_len(tokenId : Uint256) -> (res : felt):
end

@storage_var
func TRADE_fees(address: felt) -> (fee: Uint256):
end

@storage_var
func TRADE_paid_fees(tokenId: Uint256, address: felt) -> (success: felt):
end

@storage_var
func TRADE_trade_count(address: felt) -> (count: felt):
end

@storage_var
func TRADE_trade_idx(address: felt, idx: felt) -> (tokenId: Uint256):
end

namespace Trade:

    func init{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            counterpart: felt
        ) -> (
            tokenId: Uint256
        ):
        
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

        init_called.emit(tokenId, caller_address, counterpart)
        
        return (tokenId=tokenId)
    end

    func agree{
            pedersen_ptr: HashBuiltin*, 
            syscall_ptr: felt*, 
            range_check_ptr
        }(
            tokenId: Uint256
        ):

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
        
        let (agreed) = agreements_state.read(tokenId)
        let (timestamp) = agreements_timestamp.read(tokenId)
        let (counterpart) = agreements_counterpart.read(tokenId)
        
        return (agreed=agreed, timestamp=timestamp, counterpart_address=counterpart)
    end

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

    func agreement_terms{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            token_id : Uint256
        ) -> (
            agreement_terms_len : felt, 
            agreement_terms : felt*
        ):
        alloc_locals

        # ensure valid uint256
        with_attr error_message("token_id is not a valid Uint256"):
            uint256_check(token_id)
        end

        # ensure token with token_id exists
        let (exists) = ERC721._exists(token_id)
        with_attr error_message("nonexistent token"):
            assert exists = TRUE
        end

        let (local agreement_terms_len) = agreements_terms_len.read(token_id)

        let (local agreement_terms_value) = alloc()

        _agreement_terms(token_id, agreement_terms_len, agreement_terms_value)

        return (agreement_terms_len, agreement_terms_value)
    end


    func set_agreement_terms{
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

    func reset_agreements_terms{
            syscall_ptr : felt*, 
            pedersen_ptr : HashBuiltin*, 
            range_check_ptr
        }(
            tokenId : Uint256
        ):

        set_agreement_terms(tokenId, 0, &[0])
        return ()
    end

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

    func charge_fee{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            tokenId: Uint256,
            tokens_len: felt,
            tokens: felt*,
        ) -> ():
        alloc_locals

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
        
        charge_fee(tokenId=tokenId, tokens_len=tokens_len-1,tokens=tokens+1)

        return ()
    end
end