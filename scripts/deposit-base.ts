import hardhat from "hardhat";
import { toUint256WithFelts, fromUint256WithFelts } from "./starknetUtils"
import { FEE, walletAddressOwner, walletPrivateOwner, daoContractAddress, txFlowContractAddress, txTradeContractAddress, erc20ContractAddress, walletAddress0, walletPrivate0, walletAddress1, walletPrivate1 } from "./constants";

  
async function main() {
    console.log('TradeFlows deposit base...')

    /** Note that you must have the private keys for the owner contract **/

    const owner = (await hardhat.starknet.getAccountFromAddress(walletAddressOwner, walletPrivateOwner, 'OpenZeppelin'))

    const account0 = (await hardhat.starknet.getAccountFromAddress(walletAddress0, walletPrivate0, 'OpenZeppelin'))
    const account1 = (await hardhat.starknet.getAccountFromAddress(walletAddress1, walletPrivate1, 'OpenZeppelin'))
    
    const daoContractFactory = await hardhat.starknet.getContractFactory('tradeflows/DAO')
    const erc20ContractFactory = await hardhat.starknet.getContractFactory('openzeppelin/token/erc20/ERC20')
    const txTradeContractFactory = await hardhat.starknet.getContractFactory('tradeflows/txTrade')
    const txFlowContractFactory = await hardhat.starknet.getContractFactory('tradeflows/txFlow')

    const daoContract = await daoContractFactory.getContractAt(daoContractAddress)
    const txFlowContract = await txFlowContractFactory.getContractAt(txFlowContractAddress)
    const txTradeContract = await txTradeContractFactory.getContractAt(txTradeContractAddress)
    const erc20Contract = await erc20ContractFactory.getContractAt(erc20ContractAddress)
    
    const amount = toUint256WithFelts('10000')
    await owner.invoke(
      erc20Contract, 
      'approve', 
      { spender: txFlowContract.address, amount: amount}, 
      { maxFee: FEE}
    )

    const txHash = await owner.invoke(
      txFlowContract, 
        "depositBase", 
        { 
          amount: amount
        },
        { maxFee: FEE}
      )
    console.log('done with txHash: ', txHash)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
