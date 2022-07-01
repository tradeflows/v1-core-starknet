import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory, Account } from "hardhat/types/runtime";
import { TIMEOUT, walletAddress0, walletPrivate0, walletAddress1, walletPrivate1, txDharmaContractAddress, txFlowContractAddress, txTradeContractAddress } from "../scripts/constants";
import { feltArrToStr } from "../scripts/starknetUtils"


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

  
  before(async function() {

    console.log("Trade Counterpart Data")

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

  it("trade count", async function() {   
    const {count: count} = await account0.call(
      txTradeContract, "tradeCount",
      { 
        counterpart: account0.address,
      })

    countIn = Number(count)

    console.log('trade Count', { count: countIn })
  })

  it("trades", async function() {   
    for(let i = 0; i < countIn; i++){
      const { tokenId: tokenId } = await account0.call(
        txTradeContract, "tradeId", { 
          counterpart: account0.address, 
          idx: i
        })

      const {agreement_terms_len: len, agreement_terms: terms } = await account0.call(
        txTradeContract, "agreementTerms", { 
          tokenId: tokenId
        })
  
      
      console.log('terms', tokenId, JSON.parse(feltArrToStr(terms)))
    }
  })
})
