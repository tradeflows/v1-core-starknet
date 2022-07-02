import hardhat from "hardhat";
import { toUint256WithFelts, fromUint256WithFelts } from "./starknetUtils"
import { walletAddressOwner, walletPrivateOwner, daoContractAddress, txFlowContractAddress, txTradeContractAddress, erc20ContractAddress, walletAddress0, walletPrivate0, walletAddress1, walletPrivate1 } from "./constants";

  
async function main() {
    console.log('TradeFlows check erc20 balances...')

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
    
    let tokenId = toUint256WithFelts("0")

    const datao = await owner.call(erc20Contract, "balanceOf", { account: owner.starknetContract.address })
    const data0 = await owner.call(erc20Contract, "balanceOf", { account: account1.starknetContract.address })
    const data1 = await owner.call(erc20Contract, "balanceOf", { account: account1.starknetContract.address })
    const datac = await owner.call(erc20Contract, "balanceOf", { account: txFlowContract.address })
    const datad = await owner.call(erc20Contract, "balanceOf", { account: daoContract.address })

    let bo = (fromUint256WithFelts(datao.balance).toString())
    let b0 = (fromUint256WithFelts(data0.balance).toString())
    let b1 = (fromUint256WithFelts(data1.balance).toString())
    let bc = (fromUint256WithFelts(datac.balance).toString())
    let bd = (fromUint256WithFelts(datad.balance).toString())

    console.log('owner            ', bo)
    console.log('balance account 0', b0)
    console.log('balance account 1', b1)
    console.log('balance escrow   ', bc)
    console.log('balance dao      ', bd)
    
    console.log('total', (BigInt(bo) + BigInt(b0) + BigInt(b1) + BigInt(bc) + BigInt(bd)).toString())
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
