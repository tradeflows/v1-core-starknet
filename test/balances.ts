import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory, Account } from "hardhat/types/runtime";
import { TIMEOUT, walletAddress0, walletPrivate0, walletAddress1, walletPrivate1, txDharmaContractAddress, txFlowContractAddress, txTradeContractAddress } from "../scripts/constants";
import { toUint256WithFelts, fromUint256WithFelts } from "../scripts/starknetUtils"

describe("account / nft balances", function () {
  this.timeout(TIMEOUT);

  let txFlowContractFactory: StarknetContractFactory;
  let txFlowContract: StarknetContract;
  let txTradeContractFactory: StarknetContractFactory;
  let txTradeContract: StarknetContract;
  let txDharmaContractFactory: StarknetContractFactory;
  let txDharmaContract: StarknetContract;
  
  let account0: Account;
  let account1: Account;

  const tokenId = toUint256WithFelts('0')
  
  before(async function() {

    console.log("Load Accounts start")

    account0 = (await starknet.getAccountFromAddress(walletAddress0, walletPrivate0, 'OpenZeppelin'))
    account1 = (await starknet.getAccountFromAddress(walletAddress1, walletPrivate1, 'OpenZeppelin'))
        
    console.log('Account 0 address: ', account0.starknetContract.address, account0.publicKey, account0.privateKey)
    console.log('Account 1 address: ', account1.starknetContract.address, account1.publicKey, account1.privateKey)

    txFlowContractFactory = await starknet.getContractFactory('tradeflows/txFlow')
    txDharmaContractFactory = await starknet.getContractFactory('tradeflows/txDharma')
    txTradeContractFactory = await starknet.getContractFactory('tradeflows/txTrade')
    
    txFlowContract = await txFlowContractFactory.getContractAt(txFlowContractAddress)
    txDharmaContract = await txDharmaContractFactory.getContractAt(txDharmaContractAddress)
    txTradeContract = await txTradeContractFactory.getContractAt(txTradeContractAddress)

    console.log("txFlow: ", txFlowContract.address)
    console.log("txDharma: ", txDharmaContract.address)
    console.log("txTrade: ", txTradeContract.address)
  })

  it("balanceOfNFT", async function() {   
    const {balance: count} = await account0.call(
      txFlowContract, "balanceOfNFT",
      { 
        account: txTradeContract.address, 
        tokenId: tokenId
      })

    const balance = fromUint256WithFelts(count)

    console.log('balanceOfNFT', { balance: balance.toString() })
  })
});
