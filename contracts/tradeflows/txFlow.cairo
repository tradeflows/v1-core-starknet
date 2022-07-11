# SPDX-License-Identifier: MIT
# TradeFlows ERC20 Wrapper Contracts for Cairo v0.1.0 (traflows/txFlow.cairo)
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

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, get_block_number, get_block_timestamp
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc20.library import ERC20_allowances, ERC20_balances, ERC20
from openzeppelin.security.reentrancyguard import ReentrancyGuard
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.security.safemath import SafeUint256
from openzeppelin.access.ownable import Ownable

from tradeflows.library.flow import FLOW_in_count, FLOW_base_token, Flow
from tradeflows.library.trade import Trade


@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        baseToken: felt
    ):

    Flow.set_base_token(baseToken)
    
    let (decimals) = IERC20.decimals(contract_address=baseToken)
    ERC20.initializer(name, symbol, decimals)

    return ()
end

#
# Getters
#

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        name: felt
    ):

    let (name) = ERC20.name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        symbol: felt
    ):

    let (symbol) = ERC20.symbol()
    return (symbol)
end

@view
func totalSupply{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        totalSupply: Uint256
    ):

    let (totalSupply: Uint256) = ERC20.total_supply()
    return (totalSupply)
end

@view
func decimals{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        decimals: felt
    ):
    let (decimals) = ERC20.decimals()
    return (decimals)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account: felt
    ) -> (
        balance: Uint256
    ):
    alloc_locals

    let (balance: Uint256)                      = ERC20.balance_of(account)

    ## Stream Logic Start
    let (contract_address)                      = get_contract_address()

    let tokenId                                 = Uint256(0,0)

    if account == contract_address:
        let (locked_amount, _)                  = Flow.locked_amount_out(contract_address)

        return (locked_amount)
    else:

        let (block_timestamp)                   = get_block_timestamp()
        let (count)                             = FLOW_in_count.read(beneficiary=account, tokenId=tokenId)

        let (available_amount, locked_amount)   = Flow.aggregated_amount(account, tokenId, block_timestamp, count)

        let (res)                               = SafeUint256.add(available_amount, balance)        
        return (res)
    end
end

@view
func balanceOfNFT{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account: felt,
        tokenId: Uint256
    ) -> (
        balance: Uint256
    ):
    alloc_locals

    let (balance: Uint256) = ERC20.balance_of(account)

    ## Stream Logic Start
    let (contract_address)                      = get_contract_address()

    if account == contract_address:
        let (locked_amount, _)                  = Flow.locked_amount_out(contract_address)

        return (locked_amount)
    else:

        let (block_timestamp)                   = get_block_timestamp()
        let (count)                             = FLOW_in_count.read(beneficiary=account, tokenId=tokenId)

        let (available_amount, locked_amount)   = Flow.aggregated_amount(account, tokenId, block_timestamp, count)
        
        let (res) = SafeUint256.add(available_amount, balance)        
        return (res)
    end
end

@view
func allowance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owner: felt, 
        spender: felt
    ) -> (
        remaining: Uint256
    ):
    let (remaining: Uint256) = ERC20.allowance(owner, spender)
    return (remaining)
end

#
# Externals
#

@external
func transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        recipient: felt, 
        amount: Uint256
    ) -> (
        success: felt
    ):

    let (caller_address)    = get_caller_address()
    let tokenId             = Uint256(0,0)

    Flow.withdraw(caller_address, tokenId, FALSE, FALSE)
    ERC20.transfer(recipient, amount)
    let (base_address)= FLOW_base_token.read()
    return (TRUE)
end

@external
func transferFrom{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        sender: felt, 
        recipient: felt, 
        amount: Uint256
    ) -> (
        success: felt
    ):

    let (caller_address)    = get_caller_address()
    let tokenId            = Uint256(0,0)

    Flow.withdraw(caller_address, tokenId, FALSE, FALSE)
    ERC20.transfer_from(sender, recipient, amount)
    return (TRUE)
end

@external
func approve{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        spender: felt, 
        amount: Uint256
    ) -> (
        success: felt
    ):

    ERC20.approve(spender, amount)
    return (TRUE)
end

@external
func increaseAllowance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        spender: felt, 
        added_value: Uint256
    ) -> (
        success: felt
    ):

    ERC20.increase_allowance(spender, added_value)
    return (TRUE)
end

@external
func decreaseAllowance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        spender: felt, 
        subtracted_value: Uint256
    ) -> (
        success: felt
    ):

    ERC20.decrease_allowance(spender, subtracted_value)
    return (TRUE)
end

@external
func mint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(to: felt, amount: Uint256):
    Ownable.assert_only_owner()
    ERC20._mint(to, amount)
    return ()
end

@external
func burn{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(to: felt, amount: Uint256):
    Ownable.assert_only_owner()
    ERC20._burn(to, amount)
    return ()
end

@external
func transferOwnership{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(newOwner: felt):
    Ownable.transfer_ownership(newOwner)
    return ()
end

@external
func renounceOwnership{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }():
    Ownable.renounce_ownership()
    return ()
end

#
# txFlow Custom functionality
#

#
# Getters
#

# Returns the current state.
@view
func state{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }() -> (
        block_number: felt, 
        block_timestamp: felt
    ):

    let (block_number)      = get_block_number()
    let (block_timestamp)   = get_block_timestamp()


    return (block_number=block_number, block_timestamp=block_timestamp)    
end

# Get the available and locked amounts to the caller wallet is able to withdraw
@view
func withdrawAmount{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt
    ) -> (
        available_amount: Uint256, 
        locked_amount: Uint256, 
        block_timestamp: felt
    ):

    let tokenId  = Uint256(0,0)

    let (caller) = get_caller_address()

    let (available_amount, locked_amount, block_timestamp) = Flow.get_withdraw_amount(beneficiary_address, tokenId, caller)
    return (available_amount=available_amount, locked_amount=locked_amount, block_timestamp=block_timestamp)
end

# Get the available and locked amounts to the caller wallet is able to withdraw
@view
func withdrawAmountNFT{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt, 
        beneficiary_tokenId: Uint256,
    ) -> (
         available_amount: Uint256, 
         locked_amount: Uint256, 
         block_timestamp: felt
    ):

    let (caller) = get_caller_address()
    let (available_amount, locked_amount, block_timestamp) = Flow.get_withdraw_amount(beneficiary_address, beneficiary_tokenId, caller)
    return (available_amount=available_amount, locked_amount=locked_amount, block_timestamp=block_timestamp)
end

# Get the locked amount to be paid by the caller wallet to others.
@view
func lockedOut{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        payer_address: felt
    ) -> (
        locked_amount: Uint256, 
        block_timestamp: felt
    ):
    
    let (locked_amount, block_timestamp) = Flow.locked_amount_out(payer_address)
    return (locked_amount=locked_amount, block_timestamp=block_timestamp)
end

# Get the current count of the in streams of the caller wallet
@view
func countIn{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt,
        beneficiary_tokenId: Uint256
    ) -> (
        count: felt
    ):

    # let tokenId = Uint256(0,0)

    let (count) = Flow.maturity_stream_count_in(beneficiary_address, beneficiary_tokenId)
    return (count=count)
end

# Get the current count of the out streams of the caller wallet
@view
func countOut{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        payer_address: felt
    ) -> (
        count: felt
    ):

    let (count) = Flow.maturity_stream_count_out(payer_address)
    return (count=count)
end

# Get the stream paid from wallet
@view
func streamIn{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt, 
        beneficiary_tokenId: Uint256,
        idx: felt
    ) -> (
        from_address: felt, 
        amount: Uint256, 
        initial_amount: Uint256, 
        last_withdraw: Uint256, 
        start_time: felt, 
        last_reset_time: felt, 
        maturity_time: felt
    ):

    let (from_address, amount, initial_amount, last_withdraw, start_time, last_reset_time, maturity_time) = Flow.stream_in(beneficiary_address, beneficiary_tokenId, idx)
    return (from_address=from_address, amount=amount, initial_amount=initial_amount, last_withdraw=last_withdraw, start_time=start_time, last_reset_time=last_reset_time, maturity_time=maturity_time)
end

# Get the stream paid to wallet
@view
func streamOut{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt, 
        beneficiary_tokenId: Uint256,
        idx: felt
    ) -> (
        from_address: felt, 
        amount: Uint256, 
        initial_amount: Uint256, 
        last_withdraw: Uint256, 
        start_time: felt, 
        last_reset_time: felt, 
        maturity_time: felt
    ):
    let (from_address, amount, initial_amount, last_withdraw, start_time, last_reset_time, maturity_time) = Flow.stream_out(beneficiary_address, beneficiary_tokenId, idx)
    return (from_address=from_address, amount=amount, initial_amount=initial_amount, last_withdraw=last_withdraw, start_time=start_time, last_reset_time=last_reset_time, maturity_time=maturity_time)
end



#
# Externals
#

# Withdrawn any available amount.
@external
func withdraw{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt
    ) -> (
        amount: Uint256, 
        locked_amount: Uint256
    ):
    ReentrancyGuard._start()
    let (amount, locked_amount) = Flow.withdraw(beneficiary_address, Uint256(0,0), FALSE, FALSE)
    ReentrancyGuard._end()
    return (amount=amount, locked_amount=locked_amount)
end

# Withdrawn any available amount to the owner of a NFT.
@external
func withdrawNFT{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt,
        beneficiary_tokenId: Uint256
    ) -> (
        amount: Uint256, 
        locked_amount: Uint256
    ):
    ReentrancyGuard._start()
    let (amount, locked_amount) = Flow.withdraw(beneficiary_address, beneficiary_tokenId, TRUE, FALSE)
    ReentrancyGuard._end()
    return (amount=amount, locked_amount=locked_amount)
end

# Pause / Unpause all payments
@external
func pause{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt,
        beneficiary_tokenId: Uint256,
        pause: felt
    ) -> (
        amount: Uint256, 
        locked_amount: Uint256
    ):
    ReentrancyGuard._start()
    let (amount, locked_amount) = Flow.withdraw(beneficiary_address, beneficiary_tokenId, TRUE, pause)
    ReentrancyGuard._end()
    return (amount=amount, locked_amount=locked_amount)
end

# Add a new payment stream
@external
func addMaturityStream{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt, 
        target_amount: Uint256, 
        initial_amount: Uint256, 
        start: felt,
        maturity: felt
    ) -> (
        caller_address: felt
    ):
    ReentrancyGuard._start()
    let (payer_address)     = get_caller_address()
    let (contract_address)  = get_contract_address()

    let (block_timestamp)   = get_block_timestamp()

    let beneficiary_tokenId = Uint256(0,0)

    with_attr error_message("Cannot add stream to custody contract"):
        assert_not_equal(payer_address, contract_address)
    end 

    let (caller_address)    = Flow.add_maturity_stream(beneficiary_address, beneficiary_tokenId, target_amount, initial_amount, start, maturity, FALSE)
    ReentrancyGuard._end()
    return (caller_address=caller_address)
end

# Add a new payment stream
@external
func addNFTMaturityStream{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt, 
        beneficiary_tokenId: Uint256, 
        target_amount: Uint256, 
        initial_amount: Uint256, 
        start: felt,
        maturity: felt
    ) -> (
        caller_address: felt
    ):
    ReentrancyGuard._start()
    let (payer_address)   = get_caller_address()
    let (contract_address)= get_contract_address()
    let (block_timestamp) = get_block_timestamp()

    with_attr error_message("Cannot add stream to custody contract"):
        assert_not_equal(payer_address, contract_address)
    end 

    let (caller_address) = Flow.add_maturity_stream(beneficiary_address, beneficiary_tokenId, target_amount, initial_amount, start, maturity, TRUE)
    ReentrancyGuard._end()
    return (caller_address=caller_address)
end

# Increase locked amount for an existing stream
@external
func increaseAmount{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        beneficiary_address: felt, 
        beneficiary_tokenId: Uint256, 
        id: felt,
        amount: Uint256
    ) -> ():
    ReentrancyGuard._start()
    Flow.increase_amount(beneficiary_address, beneficiary_tokenId, id, amount)
    ReentrancyGuard._end()
    return ()
end

# Decrease locked amount for an existing stream
@external
func decreaseAmount{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        beneficiary_address: felt, 
        beneficiary_tokenId: Uint256, 
        id: felt,
        amount: Uint256
    ) -> ():
    ReentrancyGuard._start()
    Flow.decrease_amount(beneficiary_address, beneficiary_tokenId, id, amount)
    ReentrancyGuard._end()
    return ()
end

# Deposit base token
@external
func depositBase{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        amount: Uint256
    ) -> ():
    ReentrancyGuard._end()
    Flow.deposit_base(amount)
    ReentrancyGuard._end()
    return ()
end

# Withdraw base token
@external
func withdrawBase{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        amount: Uint256
    ) -> ():
    ReentrancyGuard._start()
    Flow.withdray_base(amount)
    ReentrancyGuard._end()
    return ()
end

