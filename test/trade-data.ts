import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory, Account } from "hardhat/types/runtime";
import { TIMEOUT, walletAddress0, walletPrivate0, walletAddress1, walletPrivate1, txDharmaContractAddress, txFlowContractAddress, txTradeContractAddress } from "../scripts/constants";
import { toUint256WithFelts } from "../scripts/starknetUtils"

describe("Trade Data", function () {
  this.timeout(TIMEOUT);

  let txFlowContractFactory: StarknetContractFactory;
  let txFlowContract: StarknetContract;
  let txTradeContractFactory: StarknetContractFactory;
  let txTradeContract: StarknetContract;
  let txDharmaContractFactory: StarknetContractFactory;
  let txDharmaContract: StarknetContract;
  
  let account0: Account;
  let account1: Account;

  const tokenId = toUint256WithFelts('2')
  
  before(async function() {

    console.log("Trade Data")

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

  let countIn = 0

  it("countIn", async function() {   
    const {count: count} = await account0.call(
      txFlowContract, "countIn",
      { 
        beneficiary_address: txTradeContract.address, 
        beneficiary_tokenId: tokenId
      })

    countIn = Number(count)

    console.log('countIn', { count: countIn })
  })

  it("streamIn", async function() {   
    for(let i = 0; i < countIn; i++){
      const data = await account0.call(
        txFlowContract, "streamIn",
        { 
          beneficiary_address: txTradeContract.address, 
          beneficiary_tokenId: tokenId,
          idx: i
        })
  
      
      console.log('streamIn', i, data)
    }
  })
});
