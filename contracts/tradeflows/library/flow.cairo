# SPDX-License-Identifier: MIT
# TradeFlows Flow library for Cairo v0.1.0 (traflows/library/flow.cairo)
# Author: @NumbersDeFi

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_eq,
    uint256_le,
    uint256_check
)
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
    assert_nn,
    assert_not_equal
)
from starkware.cairo.common.alloc import alloc

from openzeppelin.token.erc20.library import ERC20_allowances, ERC20_balances,ERC20
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.security.safemath import SafeUint256
from openzeppelin.access.ownable import Ownable

from tradeflows.interfaces.ItxTrade import ItxTrade

# Maturity Stream 
struct MaturityStreamStructure:
    member payer            : felt
    member beneficiary      : felt
    member tokenId          : Uint256
    member target_amount    : Uint256
    member locked_amount    : Uint256
    member total_withdraw   : Uint256
    member last_withdraw    : Uint256
    member start_time       : felt
    member last_reset_time  : felt
    member maturity_time    : felt
    member is_nft           : felt
    member is_paused        : felt
end

# Event that an interim withdraw has occurred
@event
func withdraw_called(payer: felt, amount: Uint256, locked_amount: Uint256, total_withdraw: Uint256, start_time: felt, maturity_time: felt, block_time: felt):
end

# Event that an aggregated withdraw has occurred
@event
func withdraw_total_called(payer: felt, amount: Uint256, locked_amount: Uint256, block_time: felt):
end

# Event that a maturity stream has been added
@event
func add_maturity_stream_called(flow_id: felt, payer: felt, target_amount: Uint256, initial_amount: Uint256, count: felt, start_time: felt, last_reset_time: felt, maturity_time: felt):
end

# Storage of the counter of the number of streams to be payed TO a given user.
@storage_var
func FLOW_in_count(beneficiary: felt, tokenId: Uint256) -> (count: felt):
end

# Storage of the stream given the receivers address and the stream's index.
@storage_var
func FLOW_in(beneficiary: felt, tokenId: Uint256, idx: felt) -> (data: MaturityStreamStructure):
end

# Storage of the counter of the number of streams to be payed BY a given user.
@storage_var
func FLOW_out_count(payer: felt) -> (count: felt):
end

# Storage of the receiver's index of a stream given the payers address.
@storage_var
func FLOW_out_idx(payer: felt, idx: felt) -> (to_idx: felt):
end

# Storage of the receiver's address of a stream given the payers address.
@storage_var
func FLOW_out_address(payer: felt, idx: felt) -> (beneficiary: felt):
end

# Storage of the receiver's address of a stream given the payers address.
@storage_var
func FLOW_out_tokenId(payer: felt, idx: felt) -> (tokenId: Uint256):
end

# Storage of the base token address
@storage_var
func FLOW_base_token() -> (token_address: felt):
end


namespace Flow:

    # Set the base token
    func set_base_token{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
             base_token: felt
        ) -> ():

        FLOW_base_token.write(base_token)

        return ()
    end 

    # Deposit token
    func deposit_base{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
             amount: Uint256
        ) -> ():
        alloc_locals
        let (local base_address)= FLOW_base_token.read()
        let (payer_address)     = get_caller_address()
        let (contract_address)  = get_contract_address()
        let (allowance)         = IERC20.allowance(contract_address=base_address, owner=payer_address, spender=contract_address)
        
        with_attr error_message("amount must be less than or equal to allowance"):
            let (ok) = uint256_le(amount,allowance)
            assert ok = TRUE
        end

        IERC20.transferFrom(contract_address=base_address, sender=payer_address, recipient=contract_address, amount=amount)
        ERC20._mint(payer_address, amount)
        
        return ()
    end 

    # Withdraw token
    func withdray_base{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            amount: Uint256
        ) -> ():
        alloc_locals
        let (local base_address)= FLOW_base_token.read()
        let (payer_address)     = get_caller_address()
        let (contract_address)  = get_contract_address()
        let (allowance)         = ERC20.balance_of(payer_address)

        let (contract_balance)  = IERC20.balanceOf(contract_address=base_address, account=contract_address)

        with_attr error_message("Flow: amount is not a valid Uint256"):
            uint256_check(amount)
        end
        
        with_attr error_message("base_address cannot be null"):
            assert_not_equal(base_address, 0)
        end
    
        with_attr error_message("payer_address cannot be null"):
            assert_not_equal(payer_address, 0)
        end

        with_attr error_message("contract_address cannot be null"):
            assert_not_equal(contract_address, 0)
        end

        with_attr error_message("contract balance cannot be null"):
            let (ok) = uint256_le(Uint256(0,0),contract_balance)
            assert ok = TRUE
        end

        with_attr error_message("amount must be less than or equal to allowance"):
            let (ok) = uint256_le(amount,allowance)
            assert ok = TRUE
        end

        with_attr error_message("amount must be less than or equal to contract balance"):
            let (ok) = uint256_le(amount,contract_balance)
            assert ok = TRUE
        end

        ERC20._burn(payer_address, amount)
        IERC20.transfer(contract_address=base_address, recipient=payer_address, amount=amount)
        return ()
    end

    # Returns the current state.
    func get_state{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }() -> (
            caller_address: felt, 
            block_number: felt, 
            block_timestamp: felt
        ):

        let (block_number)      = get_block_number()
        let (block_timestamp)   = get_block_timestamp()

        return (block_number=block_number, block_timestamp=block_timestamp)    
    end

    # Add a new payment stream
    func add_maturity_stream{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            beneficiary_address: felt,
            beneficiary_tokenId: Uint256,
            target_amount: Uint256,
            initial_amount: Uint256,
            start: felt,
            maturity: felt,
            is_nft: felt
        ) -> (
            caller_address : felt
        ):

        alloc_locals

        with_attr error_message("beneficiary_tokenId is not a valid Uint256"):
            uint256_check(beneficiary_tokenId)
        end

        with_attr error_message("target_amount is not a valid Uint256"):
            uint256_check(target_amount)
        end

        with_attr error_message("initial_amount is not a valid Uint256"):
            uint256_check(initial_amount)
        end
        

        let uint256_0 = Uint256(0,0)

        let (block_timestamp)   = get_block_timestamp()

        with_attr error_message("maturity must be greater than current block timestamp"):
            assert_lt(block_timestamp,maturity)
        end

        let (contract_address)  = get_contract_address()
        let (payer_address)     = get_caller_address()
        let (allowance)         = ERC20.allowance(payer_address, contract_address)

        with_attr error_message("fee not paid by trade owner"):
            let (ok) = ItxTrade.canAddPayment(contract_address=beneficiary_address, tokenId=beneficiary_tokenId, tokenAddress=contract_address)
            assert ok = TRUE
        end

        
        with_attr error_message("amount must be less than or equal to allowance"):
            let (ok) = uint256_le(initial_amount,allowance)
            assert ok = TRUE
        end
        
        let new_stream          = MaturityStreamStructure(payer=payer_address, beneficiary=beneficiary_address, tokenId=beneficiary_tokenId, target_amount=target_amount, locked_amount=initial_amount, total_withdraw=uint256_0, last_withdraw=uint256_0, start_time=start, last_reset_time=start, maturity_time=maturity, is_nft=is_nft, is_paused=FALSE)

        let (count)             = FLOW_in_count.read(beneficiary=beneficiary_address, tokenId=beneficiary_tokenId)

        FLOW_in.write(beneficiary_address, beneficiary_tokenId, count, new_stream)

        let (count_to)          = FLOW_out_count.read(payer=payer_address)

        FLOW_out_address.write(payer_address, count_to, beneficiary_address)
        FLOW_out_tokenId.write(payer_address, count_to, beneficiary_tokenId)
        FLOW_out_idx.write(payer_address, count_to, count)

        let (custody_count_to)  = FLOW_out_count.read(payer=contract_address)
        
        FLOW_out_address.write(contract_address, custody_count_to, beneficiary_address)
        FLOW_out_tokenId.write(contract_address, custody_count_to, beneficiary_tokenId)
        FLOW_out_idx.write(contract_address, custody_count_to, count)


        let new_count           = count + 1
        FLOW_in_count.write(beneficiary_address, beneficiary_tokenId, new_count)

        let new_count_to        = count_to + 1
        FLOW_out_count.write(payer_address, new_count_to)

        let new_custody_count_to= custody_count_to + 1
        FLOW_out_count.write(contract_address, new_custody_count_to)
        
        add_maturity_stream_called.emit(flow_id= count, payer=payer_address, target_amount=target_amount, initial_amount=initial_amount, count=new_count, start_time=start, last_reset_time=start, maturity_time=maturity)
        
        ERC20.transfer(contract_address, initial_amount)

        return (caller_address=payer_address)
    end

    # Increase locked amount for an existing stream
    func increase_amount{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            beneficiary_address: felt,
            beneficiary_tokenId: Uint256,
            id: felt,
            amount: Uint256
        ) -> (
            caller_address : felt
        ):

        alloc_locals

        with_attr error_message("beneficiary_tokenId is not a valid Uint256"):
            uint256_check(beneficiary_tokenId)
        end

        with_attr error_message("amount is not a valid Uint256"):
            uint256_check(amount)
        end

        let uint256_0 = Uint256(0,0)

        let (block_timestamp)   = get_block_timestamp()

        let (contract_address)  = get_contract_address()
        let (payer_address)     = get_caller_address()

        let (stream)            = FLOW_in.read(beneficiary_address, beneficiary_tokenId, id)

        let (new_amount)        = SafeUint256.add(stream.locked_amount, amount)

        with_attr error_message("amount must be less than target amount"):
            let (ok) = uint256_le(new_amount, stream.target_amount)
            assert ok = TRUE
        end

        ERC20.transfer(contract_address, amount)
        let edited_stream       = MaturityStreamStructure(payer=stream.payer, beneficiary=stream.beneficiary, tokenId=stream.tokenId, target_amount=stream.target_amount, locked_amount=new_amount, total_withdraw=stream.total_withdraw, last_withdraw=stream.last_withdraw, start_time=stream.start_time, last_reset_time=stream.last_reset_time, maturity_time=stream.maturity_time, is_nft=stream.is_nft, is_paused=stream.is_paused)
        FLOW_in.write(beneficiary_address, beneficiary_tokenId, id, edited_stream)

        
        return (caller_address=payer_address)
    end

    # Decrease locked amount for an existing stream
    func decrease_amount{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            beneficiary_address: felt,
            beneficiary_tokenId: Uint256,
            id: felt,
            amount: Uint256
        ) -> (
            caller_address : felt
        ):

        alloc_locals

        with_attr error_message("beneficiary_tokenId is not a valid Uint256"):
            uint256_check(beneficiary_tokenId)
        end
        with_attr error_message("amount is not a valid Uint256"):
            uint256_check(amount)
        end

        let uint256_0 = Uint256(0,0)

        let (block_timestamp)   = get_block_timestamp()

        let (contract_address)  = get_contract_address()
        let (payer_address)     = get_caller_address()

        let (stream)            = FLOW_in.read(beneficiary_address, beneficiary_tokenId, id)

        with_attr error_message("amount must be less or equal to locked amount"):
            let (new_amount)    = SafeUint256.sub_le(stream.locked_amount, amount)
        end

        ERC20_allowances.write(contract_address, payer_address, amount)
        ERC20.transfer_from(contract_address, payer_address, amount)


        let edited_stream       = MaturityStreamStructure(payer=stream.payer, beneficiary=stream.beneficiary, tokenId=stream.tokenId, target_amount=stream.target_amount, locked_amount=new_amount, total_withdraw=stream.total_withdraw, last_withdraw=stream.locked_amount, start_time=stream.start_time, last_reset_time=block_timestamp, maturity_time=stream.maturity_time, is_nft=stream.is_nft, is_paused=stream.is_paused)
        FLOW_in.write(beneficiary_address, beneficiary_tokenId, id, edited_stream)

        
        return (caller_address=payer_address)
    end

    # Get the current count of the in streams of the caller wallet
    func maturity_stream_count_in{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            beneficiary_address: felt,
            beneficiary_tokenId: Uint256
        ) -> (
            count: felt
        ):

        with_attr error_message("beneficiary_tokenId is not a valid Uint256"):
            uint256_check(beneficiary_tokenId)
        end

        let (count)             = FLOW_in_count.read(beneficiary=beneficiary_address, tokenId=beneficiary_tokenId)
        
        return (count=count)
    end

    # Get the current count of the out streams of the caller wallet
    func maturity_stream_count_out{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            payer_address: felt
        ) -> (
            count: felt
        ):

        let (count)             = FLOW_out_count.read(payer=payer_address)
        
        return (count=count)
    end

    # Get the stream paid from wallet
    func stream_in{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            beneficiary_address: felt, 
            beneficiary_tokenId: Uint256,
            idx: felt
        ) -> (
            payer: felt, 
            amount: Uint256, 
            total_withdraw: Uint256, 
            last_withdraw: Uint256, 
            start_time: felt, 
            last_reset_time: felt, 
            maturity_time: felt
        ):

        with_attr error_message("beneficiary_tokenId is not a valid Uint256"):
            uint256_check(beneficiary_tokenId)
        end
        
        let (stream) = FLOW_in.read(beneficiary=beneficiary_address, tokenId=beneficiary_tokenId, idx=idx)

        return (payer=stream.payer, amount=stream.locked_amount, total_withdraw=stream.total_withdraw, last_withdraw=stream.last_withdraw, start_time=stream.start_time, last_reset_time=stream.last_reset_time, maturity_time=stream.maturity_time)
    end

    # Get the stream paid to wallet
    func stream_out{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            beneficiary_address: felt, 
            beneficiary_tokenId: Uint256,
            idx: felt
        ) -> (
            payer: felt, 
            amount: Uint256, 
            total_withdraw: Uint256, 
            last_withdraw: Uint256, 
            start_time: felt, 
            last_reset_time: felt, 
            maturity_time: felt
        ):

        with_attr error_message("beneficiary_tokenId is not a valid Uint256"):
            uint256_check(beneficiary_tokenId)
        end
        
        let (stream) = FLOW_in.read(beneficiary=beneficiary_address, tokenId=beneficiary_tokenId, idx=idx)

        return (payer=stream.payer, amount=stream.locked_amount, total_withdraw=stream.total_withdraw, last_withdraw=stream.last_withdraw, start_time=stream.start_time, last_reset_time=stream.last_reset_time, maturity_time=stream.maturity_time)
    end

    # calculate the amount available and locked
    func calc_stream{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            stream: MaturityStreamStructure,
            block_timestamp: felt
        ) -> (
            available_amount: Uint256, 
            locked_amount: Uint256
        ):
        alloc_locals

        if stream.is_paused == TRUE:
            return (available_amount=Uint256(0,0), locked_amount=stream.locked_amount)
        end

        let (maturity_le_block)         = is_le(stream.maturity_time, block_timestamp)
        if maturity_le_block == TRUE:
            return (available_amount= stream.locked_amount, locked_amount=Uint256(0,0))
        end

        let time_elapsed                = block_timestamp - stream.last_reset_time 
        let time_total                  = stream.maturity_time - stream.last_reset_time

        let time_elapsed_uint256        = Uint256(low=time_elapsed, high=0)
        let time_total_uint256          = Uint256(low=time_total, high=0)
        
        let (amount_time_elapsed, _)    = SafeUint256.div_rem(stream.target_amount, time_total_uint256)
        let (payout)                    = SafeUint256.mul(amount_time_elapsed, time_elapsed_uint256)

        let (locked)                    = SafeUint256.sub_le(stream.locked_amount, payout)
        
        let (error)                     = uint256_le(stream.locked_amount, payout)
        if error == TRUE:
            return (available_amount=stream.locked_amount, locked_amount=Uint256(0,0))
        end    
        
        return (available_amount=payout, locked_amount=locked)
    end

    # Recursive helper function to get the available and locked amounts to the caller wallet is able to withdraw
    func aggregated_amount{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            beneficiary_address: felt, 
            beneficiary_tokenId: Uint256,
            block_timestamp: felt, 
            idx: felt
        ) -> (
            available_amount: Uint256, 
            locked_amount: Uint256
        ):

        alloc_locals

        with_attr error_message("beneficiary_tokenId is not a valid Uint256"):
            uint256_check(beneficiary_tokenId)
        end

        let uint256_0 = Uint256(0,0)

        if idx == -1:
            return (available_amount=uint256_0, locked_amount=uint256_0)
        end

        let (inner_available_amount, inner_locked_amount) = aggregated_amount(beneficiary_address=beneficiary_address, beneficiary_tokenId=beneficiary_tokenId, block_timestamp=block_timestamp, idx=idx-1)
        
        let (stream)                    = FLOW_in.read(beneficiary=beneficiary_address, tokenId=beneficiary_tokenId, idx=idx)

        if stream.is_paused == TRUE:
            let (locked_amount)         = SafeUint256.add(stream.locked_amount, inner_locked_amount)
            return (available_amount= inner_available_amount, locked_amount=locked_amount)
        end

        let (start_le_block)            = is_le(block_timestamp-1, stream.start_time)
        if start_le_block == TRUE:
            let (locked_amount)         = SafeUint256.add(stream.locked_amount, inner_locked_amount)
            return (available_amount= inner_available_amount, locked_amount=locked_amount)
        end
        
        let (payout, locked)            = calc_stream(stream=stream, block_timestamp=block_timestamp)

        let (available_amount)          = SafeUint256.add(payout, inner_available_amount)

        let (locked_amount)             = SafeUint256.add(locked, inner_locked_amount)
        return (available_amount=available_amount, locked_amount=locked_amount)
    end

    # Get the available and locked amounts to the caller wallet is able to withdraw
    func get_withdraw_amount{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            beneficiary_address: felt,
            beneficiary_tokenId: Uint256
        ) -> (
            available_amount: Uint256, 
            locked_amount: Uint256, 
            block_timestamp: felt
        ):

        alloc_locals

        with_attr error_message("beneficiary_tokenId is not a valid Uint256"):
            uint256_check(beneficiary_tokenId)
        end

        let (block_timestamp)                   = get_block_timestamp()
        let (count)                             = FLOW_in_count.read(beneficiary=beneficiary_address, tokenId=beneficiary_tokenId)

        let (available_amount, locked_amount)   = aggregated_amount(beneficiary_address, beneficiary_tokenId, block_timestamp, count)
        
        return (available_amount=available_amount, locked_amount=locked_amount, block_timestamp=block_timestamp)
    end

    # Recursive helper function to get the locked amount to be paid by the caller wallet to others.
    func streams_aggregated_locked_amount_out{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            payer_address: felt, 
            block_timestamp: felt, 
            idx: felt
        ) -> (
            locked_amount: Uint256
        ):

        alloc_locals

        if idx == -1:
            return (locked_amount=Uint256(0,0))
        end


        let (inner_locked_amount)       = streams_aggregated_locked_amount_out(payer_address=payer_address, block_timestamp=block_timestamp, idx=idx-1)

        let (beneficiary_address)       = FLOW_out_address.read(payer=payer_address, idx=idx)
        let (beneficiary_tokenId)       = FLOW_out_tokenId.read(payer=payer_address, idx=idx)
        let (beneficiary_idx)           = FLOW_out_idx.read(payer=payer_address, idx=idx)
        
        let (stream)                    = FLOW_in.read(beneficiary=beneficiary_address, tokenId= beneficiary_tokenId, idx=beneficiary_idx)

        if stream.is_paused == TRUE:
            let (locked_amount)         = SafeUint256.add(stream.locked_amount, inner_locked_amount)
            return (locked_amount=locked_amount)
        end

        let (start_le_block)            = is_le(block_timestamp-1, stream.start_time)
        if start_le_block == TRUE:
            let (locked_amount)         = SafeUint256.add(stream.locked_amount, inner_locked_amount)
            return (locked_amount=locked_amount)
        end
        
        let (payout, locked)            = calc_stream(stream=stream, block_timestamp=block_timestamp)
        let (locked_amount)             = SafeUint256.add(locked, inner_locked_amount)
        

        return (locked_amount=locked_amount)
    end

    # Get the locked amount to be paid by the caller wallet to others.
    func locked_amount_out{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            payer_address: felt
        ) -> (
            locked_amount: Uint256, 
            block_timestamp: felt
        ):

        alloc_locals
        let (block_timestamp)           = get_block_timestamp()
        let (count)                     = FLOW_out_count.read(payer=payer_address)

        let (locked_amount)             = streams_aggregated_locked_amount_out(payer_address, block_timestamp, count)
        
        return (locked_amount=locked_amount, block_timestamp=block_timestamp)
    end

    # Recursive helper function to Withdrawn any available amount.
    func withdraw_aggregated_amount{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            beneficiary_address: felt, 
            beneficiary_tokenId: Uint256,
            block_timestamp: felt, 
            idx: felt,
            pause: felt
        ) -> (
            available_amount: Uint256, 
            locked_amount: Uint256
        ):

        alloc_locals

        with_attr error_message("beneficiary_tokenId is not a valid Uint256"):
            uint256_check(beneficiary_tokenId)
        end

        let uint256_0 = Uint256(0,0)

        if idx == -1:
            return (available_amount=uint256_0, locked_amount=uint256_0)
        end

        let (inner_available_amount, inner_locked_amount)       = withdraw_aggregated_amount(beneficiary_address=beneficiary_address, beneficiary_tokenId=beneficiary_tokenId, block_timestamp=block_timestamp, idx=idx-1, pause=pause)
        
        let (stream)                                            = FLOW_in.read(beneficiary=beneficiary_address, tokenId=beneficiary_tokenId, idx=idx)
        
        if stream.is_paused == TRUE:
            return (available_amount=uint256_0, locked_amount=uint256_0)
        end
        
        let (is_stream_amount_0)                                = uint256_eq(stream.locked_amount, uint256_0)
        if is_stream_amount_0 == TRUE:
            return (available_amount=uint256_0, locked_amount=uint256_0)
        else:        
            let (maturity_le_block)                             = is_le(stream.maturity_time, block_timestamp)

            if maturity_le_block == TRUE:
                let remaining                                   = uint256_0
                let (total_withdraw)                            = SafeUint256.add(stream.total_withdraw, stream.locked_amount)
            
                if pause == -1:
                    let edited_stream                           = MaturityStreamStructure(payer=stream.payer, beneficiary=stream.beneficiary, tokenId=stream.tokenId, target_amount=stream.target_amount, locked_amount=remaining, total_withdraw=stream.total_withdraw, last_withdraw=stream.locked_amount, start_time=stream.start_time, last_reset_time=block_timestamp, maturity_time=stream.maturity_time, is_nft=stream.is_nft, is_paused=stream.is_paused)
                    FLOW_in.write(beneficiary_address, beneficiary_tokenId, idx, edited_stream)

                    withdraw_called.emit(payer=beneficiary_address, amount=stream.locked_amount, locked_amount=uint256_0, total_withdraw= stream.total_withdraw, start_time=stream.start_time, maturity_time=stream.maturity_time, block_time=block_timestamp)

                    let (available_amount)                      = SafeUint256.add(stream.locked_amount, inner_available_amount)
                    return (available_amount=available_amount, locked_amount=inner_locked_amount)
                else:
                    let edited_stream                           = MaturityStreamStructure(payer=stream.payer, beneficiary=stream.beneficiary, tokenId=stream.tokenId, target_amount=stream.target_amount, locked_amount=remaining, total_withdraw=stream.total_withdraw, last_withdraw=stream.locked_amount, start_time=stream.start_time, last_reset_time=block_timestamp, maturity_time=stream.maturity_time, is_nft=stream.is_nft, is_paused=pause)
                    FLOW_in.write(beneficiary_address, beneficiary_tokenId, idx, edited_stream)

                    withdraw_called.emit(payer=beneficiary_address, amount=stream.locked_amount, locked_amount=uint256_0, total_withdraw= stream.total_withdraw, start_time=stream.start_time, maturity_time=stream.maturity_time, block_time=block_timestamp)

                    let (available_amount)                      = SafeUint256.add(stream.locked_amount, inner_available_amount)
                    return (available_amount=available_amount, locked_amount=inner_locked_amount)
                end
            else:
    
                if stream.is_paused == TRUE:
                    return (available_amount=inner_available_amount, locked_amount=inner_locked_amount)
                end

                let (start_le_block)                             = is_le(block_timestamp-1, stream.start_time)                
                if start_le_block == TRUE:
                    return (available_amount=inner_available_amount, locked_amount=inner_locked_amount)
                else:
                    let (payout, locked)                        = calc_stream(stream=stream, block_timestamp=block_timestamp)

                    let (total_withdraw)                        = SafeUint256.add(stream.total_withdraw, payout)

                    if pause == -1:
                        let edited_stream                       = MaturityStreamStructure(payer=stream.payer, beneficiary=stream.beneficiary, tokenId=stream.tokenId, target_amount=stream.target_amount, locked_amount=locked, total_withdraw=total_withdraw, last_withdraw=payout, start_time=stream.start_time, last_reset_time=block_timestamp, maturity_time=stream.maturity_time, is_nft=stream.is_nft, is_paused=stream.is_paused)
                        FLOW_in.write(beneficiary_address, beneficiary_tokenId, idx, edited_stream)

                        let (available_amount)                  = SafeUint256.add(payout, inner_available_amount)
                        let (locked_amount)                     = SafeUint256.add(locked, inner_locked_amount)
                

                        withdraw_called.emit(payer=beneficiary_address, amount=available_amount, locked_amount=locked_amount, total_withdraw=total_withdraw, start_time=stream.start_time, maturity_time=stream.maturity_time, block_time=block_timestamp)
                        return (available_amount=available_amount, locked_amount=locked_amount)
                    else:
                        let edited_stream                       = MaturityStreamStructure(payer=stream.payer, beneficiary=stream.beneficiary, tokenId=stream.tokenId, target_amount=stream.target_amount, locked_amount=locked, total_withdraw=total_withdraw, last_withdraw=payout, start_time=stream.start_time, last_reset_time=block_timestamp, maturity_time=stream.maturity_time, is_nft=stream.is_nft, is_paused=pause)
                        FLOW_in.write(beneficiary_address, beneficiary_tokenId, idx, edited_stream)

                        let (available_amount)                  = SafeUint256.add(payout, inner_available_amount)
                        let (locked_amount)                     = SafeUint256.add(locked, inner_locked_amount)
                

                        withdraw_called.emit(payer=beneficiary_address, amount=available_amount, locked_amount=locked_amount, total_withdraw= total_withdraw, start_time=stream.start_time, maturity_time=stream.maturity_time, block_time=block_timestamp)
                        return (available_amount=available_amount, locked_amount=locked_amount)
                    end
                end
            end
        end
    end

    # Withdrawn any available amount.
    func withdraw{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*, 
            range_check_ptr
        }(
            beneficiary_address: felt,
            beneficiary_tokenId: Uint256,
            is_nft: felt,
            pause: felt
        ) -> (
            amount: Uint256, 
            locked_amount: Uint256
        ):
        
        alloc_locals

        with_attr error_message("beneficiary_tokenId is not a valid Uint256"):
            uint256_check(beneficiary_tokenId)
        end

        let (contract_address)                       = get_contract_address()
        let (block_timestamp)                        = get_block_timestamp()

        let uint256_0 = Uint256(0,0)

        let (count)                                  = FLOW_in_count.read(beneficiary=beneficiary_address, tokenId=beneficiary_tokenId)
        let (available_amount, locked_amount)        = aggregated_amount(beneficiary_address, beneficiary_tokenId, block_timestamp, count-1)

        let (is_zero_amount) = uint256_eq(available_amount,uint256_0)

        if is_zero_amount == FALSE:
            if is_nft == TRUE:
                let (beneficiary_address_final)      = IERC721.ownerOf(contract_address=beneficiary_address, tokenId=beneficiary_tokenId)
                let (_available_amount, _locked_amount)= withdraw_aggregated_amount(beneficiary_address, beneficiary_tokenId, block_timestamp, count-1, pause)
                let (caller) = get_caller_address()
                ERC20_allowances.write(contract_address, caller, available_amount)
                ERC20.transfer_from(contract_address, beneficiary_address_final, available_amount)

                withdraw_total_called.emit(payer=beneficiary_address_final, amount=available_amount, locked_amount=locked_amount, block_time=block_timestamp)

                return (amount=available_amount, locked_amount=locked_amount)

            else:
                
                let (_available_amount, _locked_amount)= withdraw_aggregated_amount(beneficiary_address, beneficiary_tokenId, block_timestamp, count-1, pause)
                let (caller) = get_caller_address()
                ERC20_allowances.write(contract_address, caller, available_amount)
                ERC20.transfer_from(contract_address, beneficiary_address, available_amount)

                withdraw_total_called.emit(payer=beneficiary_address, amount=available_amount, locked_amount=locked_amount, block_time=block_timestamp)

                return (amount=available_amount, locked_amount=locked_amount)
                
            end
        else:
            withdraw_total_called.emit(payer=beneficiary_address, amount=available_amount, locked_amount=locked_amount, block_time=block_timestamp)

            return (amount=available_amount, locked_amount=locked_amount)

        end
    end
end