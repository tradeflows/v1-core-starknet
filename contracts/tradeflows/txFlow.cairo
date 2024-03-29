# SPDX-License-Identifier: MIT
# TradeFlows ERC20 Wrapper Contracts for Cairo v0.5.0 (tradeflows/txFlow.cairo)
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
from starkware.cairo.common.math import assert_not_equal, assert_not_zero
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc20.library import ERC20_allowances, ERC20_balances, ERC20
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.access.ownable.library import Ownable

from tradeflows.library.flow import FLOW_in, FLOW_in_count, FLOW_base_token, FLOW_id_streams, FLOW_OutFlow_address, PaymentStructure, Meta, Flow, pause_called, increase_called, decrease_called
from tradeflows.library.asset import Asset


@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        owner: felt,
        baseToken: felt
    ):

    Flow.setBaseToken(baseToken)
    
    let (decimals) = IERC20.decimals(contract_address=baseToken)
    ERC20.initializer(name, symbol, decimals)

    Ownable.initializer(owner)

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

    let (balance: Uint256)          = ERC20.balance_of(account)

    ## Stream Logic Start
    let (contract_address)          = get_contract_address()

    let tokenId                     = Uint256(0,0)

    if account == contract_address:
        let (locked_amount, _)      = Flow.lockedAmountOut(contract_address)
        return (locked_amount)
    else:

        let (block_timestamp)       = get_block_timestamp()
        let (count)                 = FLOW_in_count.read(beneficiary=account, tokenId=tokenId)

        let (available_amount, _)   = Flow.aggregatedAmount(account, tokenId, block_timestamp, count)

        let (res)                   = SafeUint256.add(available_amount, balance)        
        return (res)
    end
end

@view
func balanceOfTokenId{
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

    let (balance: Uint256)          = ERC20.balance_of(account)

    ## Stream Logic Start
    let (contract_address)          = get_contract_address()

    if account == contract_address:
        let (locked_amount, _)      = Flow.lockedAmountOut(contract_address)

        return (locked_amount)
    else:

        let (block_timestamp)       = get_block_timestamp()
        let (count)                 = FLOW_in_count.read(beneficiary=account, tokenId=tokenId)

        let (available_amount, _)   = Flow.aggregatedAmount(account, tokenId, block_timestamp, count)
        
        let (res)                   = SafeUint256.add(available_amount, balance)        
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

    let (caller_address)   = get_caller_address()
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
        beneficiary_address: felt, 
        beneficiary_tokenId: Uint256
    ) -> (
         available_amount: Uint256, 
         locked_amount: Uint256, 
         block_timestamp: felt
    ):

    let (available_amount, locked_amount, block_timestamp) = Flow.getWithdrawAmount(beneficiary_address, beneficiary_tokenId, FALSE)
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
    
    let (locked_amount, block_timestamp) = Flow.lockedAmountOut(payer_address)
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

    let (count) = Flow.paymentCountIn(beneficiary_address, beneficiary_tokenId)
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

    let (count) = Flow.paymentCountOut(payer_address)
    return (count=count)
end

# Get the stream paid from wallet
@view
func getPayment{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt, 
        beneficiary_tokenId: Uint256,
        idx: felt
    ) -> (
        paymentId: Uint256, 
        from_address: felt, 
        target: Uint256, 
        initial: Uint256,
        amount: Uint256, 
        total_withdraw: Uint256,
        last_withdraw: Uint256, 
        start_time: felt, 
        last_reset_time: felt, 
        maturity_time: felt,
        is_paused: felt,
        available_amount: Uint256,
        locked_amount: Uint256
    ):

    let (paymentId, from_address, target, initial, amount, total_withdraw, last_withdraw, start_time, last_reset_time, maturity_time, is_paused, available_amount, locked_amount) = Flow.getPayment(beneficiary_address, beneficiary_tokenId, idx)
    return (paymentId=paymentId, from_address=from_address, target=target, initial=initial, amount=amount, total_withdraw=total_withdraw, last_withdraw=last_withdraw, start_time=start_time, last_reset_time=last_reset_time, maturity_time=maturity_time, is_paused=is_paused, available_amount=available_amount, locked_amount=locked_amount)
end


#
# Externals
#



# Set OutFlow address
@external
func setOutFlowAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(address: felt):
    Ownable.assert_only_owner()
    FLOW_OutFlow_address.write(address)
    return ()
end

# Withdrawn any available amount to the owner of a NFT.
@external
func withdraw{
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
func pausePayments{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        beneficiary_address: felt,
        beneficiary_tokenId: Uint256,
        paused: felt
    ) -> (
        amount: Uint256, 
        locked_amount: Uint256
    ):
    ReentrancyGuard._start()
    let (amount, locked_amount) = Flow.withdraw(beneficiary_address, beneficiary_tokenId, TRUE, paused)
    ReentrancyGuard._end()
    return (amount=amount, locked_amount=locked_amount)
end

# Payment Input Structure
struct PaymentInput:
    member beneficiary_address  : felt
    member beneficiary_tokenId  : Uint256
    member target_amount        : Uint256
    member initial_amount       : Uint256
    member start                : felt
    member maturity             : felt
    member description          : felt

    member oracle_address       : felt
    member oracle_owner         : felt
    member oracle_key           : felt
    member oracle_value         : felt
    member creation_time        : felt
end

# Add a new payment stream
@external
func addPayments{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        input_len: felt,
        input: PaymentInput*
    ) -> (
        flowId: Uint256
    ):
    ReentrancyGuard._start()

    _addPayment(input_len=input_len,input=input)
    
    ReentrancyGuard._end()
    return (flowId=Uint256(0,0))
end

# Add a new payment stream
func _addPayment{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        input_len: felt,
        input: PaymentInput*
    ) -> ():
    if input_len == 0:
        return ()
    end
    let p = [input]
    Flow.addPayment(p.beneficiary_address, p.beneficiary_tokenId, p.target_amount, p.initial_amount, p.start, p.maturity, TRUE, p.description, p.oracle_address, p.oracle_owner, p.oracle_key, p.oracle_value)

    _addPayment(input_len=input_len-1, input=input+1)
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
    Flow.depositBase(amount)
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
    Flow.withdrawBase(amount)
    ReentrancyGuard._end()
    return ()
end

#
# ERC1155 Extentions
#

# Get the locked amount to be paid by flow given tokenId
@view
func amountTokenId{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256
    ) -> (
        available_amount: Uint256, 
        locked_amount: Uint256, 
        block_timestamp: felt
    ):
    alloc_locals

    let (idStruct)                          = FLOW_id_streams.read(tokenId)
    
    with_attr error_message("tokenId not found"):
        assert_not_zero(idStruct.beneficiary)
    end

    let (stream)                            = FLOW_in.read(idStruct.beneficiary, idStruct.tokenId, idStruct.idx)
    
    let (block_timestamp)                   = get_block_timestamp()    
    let (available_amount,locked_amount)    = Flow.calc_payment(stream, block_timestamp)
    
    return (available_amount=available_amount, locked_amount=locked_amount, block_timestamp=block_timestamp)
end

# Increase locked amount for an existing stream by tokenId
@external
func increaseTokenId{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        addrss: felt,
        tokenId: Uint256,
        amount : Uint256
    ) -> ():
    alloc_locals
    ReentrancyGuard._start()
    
    let (outFlow)           = FLOW_OutFlow_address.read()
    let (caller)            = get_caller_address()
    let (block_timestamp)   = get_block_timestamp()

    with_attr error_message("incorrect caller"):
        assert outFlow = caller
    end

    let (idStruct)          = FLOW_id_streams.read(tokenId)
    
    with_attr error_message("tokenId not found"):
        assert_not_zero(idStruct.beneficiary)
    end

    let (stream)            = FLOW_in.read(idStruct.beneficiary, idStruct.tokenId, idStruct.idx)

    with_attr error_message("only owner can call this function"):
        assert stream.payer = addrss
    end

    Flow.increaseAmount(idStruct.beneficiary, idStruct.tokenId, idStruct.idx, amount)
    increase_called.emit(beneficiary=stream.beneficiary, tokenId=stream.tokenId, paymentId=stream.paymentId, amount=amount, block_time=block_timestamp)
    ReentrancyGuard._end()
    return ()
end

# Decrease locked amount for an existing stream by tokenId
@external
func decreaseTokenId{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        addrss: felt,
        tokenId: Uint256,
        amount : Uint256
    ) -> ():
    alloc_locals
    ReentrancyGuard._start()

    let (outFlow)           = FLOW_OutFlow_address.read()
    let (caller)            = get_caller_address()
    let (block_timestamp)   = get_block_timestamp()

    with_attr error_message("incorrect caller"):
        assert outFlow = caller
    end

    let (idStruct)          = FLOW_id_streams.read(tokenId)

    with_attr error_message("tokenId not found"):
        assert_not_zero(idStruct.beneficiary)
    end

    let (stream)            = FLOW_in.read(idStruct.beneficiary, idStruct.tokenId, idStruct.idx)

    with_attr error_message("only owner can call this function"):
        assert stream.payer = addrss
    end

    Flow.decreaseAmount(idStruct.beneficiary, idStruct.tokenId, idStruct.idx, amount)

    decrease_called.emit(beneficiary=stream.beneficiary, tokenId=stream.tokenId, paymentId=stream.paymentId, amount=amount, block_time=block_timestamp)
    ReentrancyGuard._end()
    return ()
end

# Pause streaming an existing stream by tokenId
@external
func pauseTokenId{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        addrss: felt,
        tokenId: Uint256,
        paused: felt
    ) -> ():
    alloc_locals

    ReentrancyGuard._start()

    let (outFlow)           = FLOW_OutFlow_address.read()
    let (caller)            = get_caller_address()

    with_attr error_message("incorrect caller"):
        assert outFlow = caller
    end
    
    let (idStruct)          = FLOW_id_streams.read(tokenId)

    with_attr error_message("tokenId not found"):
        assert_not_zero(idStruct.beneficiary)
    end

    let (stream)            = FLOW_in.read(idStruct.beneficiary, idStruct.tokenId, idStruct.idx)

    with_attr error_message("only owner can call this function"):
        assert stream.payer = addrss
    end

    let (block_timestamp)   = get_block_timestamp()

    if stream.is_paused == FALSE:
        Flow.withdraw(beneficiary_address=stream.beneficiary, beneficiary_tokenId=stream.tokenId, is_nft=stream.is_nft, _pause=FALSE)
        let (stream)        = FLOW_in.read(idStruct.beneficiary, idStruct.tokenId, idStruct.idx)
    
        let edited_stream   = PaymentStructure(payer=stream.payer, beneficiary=stream.beneficiary, tokenId=stream.tokenId, target_amount=stream.target_amount, initial_amount=stream.initial_amount, locked_amount=stream.locked_amount, total_withdraw=stream.total_withdraw, last_withdraw=stream.last_withdraw, start_time=stream.start_time, last_reset_time=block_timestamp, maturity_time=stream.maturity_time, is_nft=stream.is_nft, is_paused=paused, paymentId=stream.paymentId, meta=stream.meta)
        FLOW_in.write(idStruct.beneficiary, idStruct.tokenId, idStruct.idx, edited_stream)
    else:
        let (stream)        = FLOW_in.read(idStruct.beneficiary, idStruct.tokenId, idStruct.idx)
        
        let edited_stream   = PaymentStructure(payer=stream.payer, beneficiary=stream.beneficiary, tokenId=stream.tokenId, target_amount=stream.target_amount, initial_amount=stream.initial_amount, locked_amount=stream.locked_amount, total_withdraw=stream.total_withdraw, last_withdraw=stream.last_withdraw, start_time=stream.start_time, last_reset_time=block_timestamp, maturity_time=stream.maturity_time, is_nft=stream.is_nft, is_paused=paused, paymentId=stream.paymentId, meta=stream.meta)
        FLOW_in.write(idStruct.beneficiary, idStruct.tokenId, idStruct.idx, edited_stream)
    end

    pause_called.emit(beneficiary=stream.beneficiary, tokenId=stream.tokenId, paymentId=stream.paymentId, flag=paused, block_time=block_timestamp)
    
    ReentrancyGuard._end()
    return ()
end

# Transfer an existing stream by tokenId
@external
func transferTokenId{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
        addrss: felt,
        tokenId: Uint256,
        addressTo: felt
    ) -> ():
    ReentrancyGuard._start()

    let (outFlow)     = FLOW_OutFlow_address.read()
    let (caller)      = get_caller_address()

    with_attr error_message("incorrect caller"):
        assert outFlow = caller
    end
    
    let (idStruct)    = FLOW_id_streams.read(tokenId)

    with_attr error_message("tokenId not found"):
        assert_not_zero(idStruct.beneficiary)
    end

    let (stream)      = FLOW_in.read(idStruct.beneficiary, idStruct.tokenId, idStruct.idx)

    with_attr error_message("only owner can call this function"):
        assert stream.payer = addrss
    end

    let edited_stream = PaymentStructure(payer=addressTo, beneficiary=stream.beneficiary, tokenId=stream.tokenId, target_amount=stream.target_amount, initial_amount=stream.initial_amount, locked_amount=stream.locked_amount, total_withdraw=stream.total_withdraw, last_withdraw=stream.last_withdraw, start_time=stream.start_time, last_reset_time=stream.last_reset_time, maturity_time=stream.maturity_time, is_nft=stream.is_nft, is_paused=stream.is_paused, paymentId=stream.paymentId, meta=stream.meta)
    FLOW_in.write(idStruct.beneficiary, idStruct.tokenId, idStruct.idx, edited_stream)
    
    ReentrancyGuard._end()
    return ()
end

