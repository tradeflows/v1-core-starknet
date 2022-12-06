# SPDX-License-Identifier: MIT
# TradeFlows OutFlows ERC1155 Contracts for Cairo v0.3.0 (tradeflows/txOutFlow.cairo)
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
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc1155.library import ERC1155
from openzeppelin.introspection.ERC165.library import ERC165

from tradeflows.interfaces.ItxFlow import ItxFlow




# Storage of the stream given the receivers address and the stream's index.
@storage_var
func OUTFLOW_baseFlow() -> (address: felt):
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        uri: felt, 
        owner: felt,
        baseFlow: felt
    ):
    ERC1155.initializer(uri)
    Ownable.initializer(owner)

    OUTFLOW_baseFlow.write(baseFlow)
    return ()
end

#
# Getters
#

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(interfaceId : felt) -> (success: felt):
    return ERC165.supports_interface(interfaceId)
end

@view
func uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}()
        -> (uri : felt):
    return ERC1155.uri()
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(
        account : felt, 
        id : Uint256
    ) -> (
        balance : Uint256
):
    let (base_address) = OUTFLOW_baseFlow.read()
    let (locked_amount: Uint256, block_timestamp: felt) = ItxFlow.lockedTokenId(contract_address=base_address, addrss=account, tokenId=id)
    return (locked_amount)
end

@view
func balanceOfBatch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        accounts_len : felt, accounts : felt*, ids_len : felt, ids : Uint256*)
        -> (balances_len : felt, balances : Uint256*):
    with_attr error_message("txOutFlow: not implemented"):
        assert_not_zero(0)
    end
    let (balances_len,balances) =  ERC1155.balance_of_batch(accounts_len, accounts, ids_len, ids)
    return (balances_len,balances)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account : felt, operator : felt) -> (is_approved : felt):
    with_attr error_message("txOutFlow: not implemented"):
        assert_not_zero(0)
    end
    let (is_approved) = ERC1155.is_approved_for_all(account, operator)
    return (is_approved)
end

#
# Externals
#

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt):
    ERC1155.set_approval_for_all(operator, approved)
    with_attr error_message("txOutFlow: not implemented"):
        assert_not_zero(0)
    end
    return ()
end

@external
func safeTransferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, to : felt, id : Uint256, amount : Uint256, data_len : felt, data : felt*):
    ERC1155.safe_transfer_from(from_, to, id, amount, data_len, data)
    with_attr error_message("txOutFlow: not implemented"):
        assert_not_zero(0)
    end
    return ()
end


@external
func safeBatchTransferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, to : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*,
        data_len : felt, data : felt*):
    ERC1155.safe_batch_transfer_from(
        from_, to, ids_len, ids, amounts_len, amounts, data_len, data)
    with_attr error_message("txOutFlow: not implemented"):
        assert_not_zero(0)
    end
    return ()
end

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, id : Uint256, amount : Uint256, data_len : felt, data : felt*):
    with_attr error_message("txOutFlow: not implemented"):
        assert_not_zero(0)
    end
    return ()
end

@external
func mintBatch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*,
        data_len : felt, data : felt*):
    with_attr error_message("txOutFlow: not implemented"):
        assert_not_zero(0)
    end
    return ()
end

@external
func burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
         from_ : felt, id : Uint256, amount : Uint256):
    with_attr error_message("txOutFlow: not implemented"):
        assert_not_zero(0)
    end
    return ()
end

@external
func burnBatch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*):
    with_attr error_message("txOutFlow: not implemented"):
        assert_not_zero(0)
    end
    return ()
end

#
# txEscrow extensions
#

# Increase amount by token id
@external
func increase{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256,
        amount: Uint256
    ):

    let (account_address)   = get_caller_address()
    let (contract_address)  = get_contract_address()
    let (base_address)      = OUTFLOW_baseFlow.read()

    IERC20.transferFrom(contract_address=base_address, sender=account_address, recipient=contract_address, amount=amount)
    IERC20.approve(contract_address=base_address, spender=base_address, amount=amount)

    ItxFlow.increaseTokenId(contract_address=base_address, addrss=account_address, tokenId=tokenId, amount=amount)
    
    return ()
end

# Decrease amount by token id
@external
func decrease{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256,
        amount: Uint256
    ):

    let (account_address)   = get_caller_address()
    let (base_address)      = OUTFLOW_baseFlow.read()

    ItxFlow.decreaseTokenId(contract_address=base_address, addrss=account_address, tokenId=tokenId, amount=amount)
    
    return ()
end

# Pause a flow
@external
func pause{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256,
        paused: felt
    ):

    let (account_address)   = get_caller_address()
    let (base_address) = OUTFLOW_baseFlow.read()
    
    ItxFlow.pauseTokenId(contract_address=base_address, addrss=account_address, tokenId=tokenId, paused=paused)
    
    return ()
end

# Transfer a flow
@external
func transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(
        tokenId: Uint256,
        address: felt
    ):

    let (account_address)   = get_caller_address()
    let (base_address) = OUTFLOW_baseFlow.read()
    
    ItxFlow.transferTokenId(contract_address=base_address, addrss=account_address, tokenId=tokenId, addressTo=address)
    
    return ()
end
