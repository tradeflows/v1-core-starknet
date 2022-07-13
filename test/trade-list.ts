import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory, Account } from "hardhat/types/runtime";
import { TIMEOUT, walletAddress0, walletPrivate0, walletAddress1, walletPrivate1, txDharmaContractAddress, txFlowContractAddress, txAssetContractAddress } from "../scripts/constants";
import { fromUint256WithFelts, feltArrToStr } from "../scripts/starknetUtils"

import { toBN } from 'starknet/dist/utils/number'

import EthCrypto from 'eth-crypto'

describe("Trade List", function () {
  this.timeout(TIMEOUT);

  let txFlowContractFactory: StarknetContractFactory;
  let txFlowContract: StarknetContract;
  let txAssetContractFactory: StarknetContractFactory;
  let txAssetContract: StarknetContract;
  let txDharmaContractFactory: StarknetContractFactory;
  let txDharmaContract: StarknetContract;
  
  let account0: Account;
  let account1: Account;

  before(async function() {

    console.log("Trade List")

    account0 = (await starknet.getAccountFromAddress(walletAddress0, walletPrivate0, 'OpenZeppelin'))
    account1 = (await starknet.getAccountFromAddress(walletAddress1, walletPrivate1, 'OpenZeppelin'))
    
    console.log('Account 0 address: ', account0.starknetContract.address, account0.publicKey, account0.privateKey)
    console.log('Account 1 address: ', account1.starknetContract.address, account1.publicKey, account1.privateKey)

    txFlowContractFactory = await starknet.getContractFactory('tradeflows/txFlow')
    txDharmaContractFactory = await starknet.getContractFactory('tradeflows/txDharma')
    txAssetContractFactory = await starknet.getContractFactory('tradeflows/txAsset')
    
    txFlowContract = await txFlowContractFactory.getContractAt(txFlowContractAddress)
    txDharmaContract = await txDharmaContractFactory.getContractAt(txDharmaContractAddress)
    txAssetContract = await txAssetContractFactory.getContractAt(txAssetContractAddress)

    console.log("txFlow: ", txFlowContract.address)
    console.log("txDharma: ", txDharmaContract.address)
    console.log("txAsset: ", txAssetContract.address)

    console.log(' --- 1 ', account1.privateKey.substring(2), Buffer.from(account1.privateKey, 'hex'))

    const publicKey = EthCrypto.publicKeyByPrivateKey(account1.privateKey.substring(2))
    console.log(' --- 2 ', publicKey)
  })

  let count = 0

  it("balance", async function() {   
    const {balance: balance} = await account0.call(
      txAssetContract, "balanceOf",
      { 
        owner: account1.address, 
      })

    count = toBN(fromUint256WithFelts(balance)).toNumber()
    console.log('balance', count, balance)
  })

  it("tokens", async function() {   
    for(let i = 0; i < count; i++){
      const { tokenId: tokenId_i} = await account0.call(
        txAssetContract, "tokenOfOwnerByIndex",
        { 
          owner: account1.address,
          index: { low: i, high: 0n }
        })

      const tokenId = tokenId_i.high
      
      console.log('token', i, tokenId)
    }
  })

  it("info", async function() {   
    for(let i = 0; i < count; i++){
      const {agreement_terms_len: len, agreement_terms: terms } = await account0.call(
        txAssetContract, "agreementTerms", { 
          tokenId: { low: 0n, high: i }
        })
      
      console.log('terms', i, JSON.parse(feltArrToStr(terms)))
    }
  })
});
