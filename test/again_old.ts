import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory, Account } from "hardhat/types/runtime";
import { TIMEOUT, FEE, ETH_WEI, walletAddress0, walletPrivate0, walletAddress1, walletPrivate1, txDharmaContractAddress, txFlowContractAddress, txTradeContractAddress } from "../scripts/constants";
import { to_uint, from_uint } from "../scripts/util"
import { strToFeltArr } from "../scripts/starknetUtils"

let tradeId = 2

describe("Run Workflow Again", function () {
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

    console.log("Run Workflow Again")

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

  it("init txTrade", async function() {   
    try{
      
      let tradeInfo = {
        counterPart: 'Jane Doe',
        description: 'I hope that a study of very long sentences will arm you with strategies that are almost as diverse as the sentences themselves, such as: starting each clause with the same word, tilting with dependent clauses toward a revelation at the end, padding with parentheticals, showing great latitude toward standard punctuation, rabbit-trailing away from the initial subject, encapsulating an entire life, and lastly, as this sentence is, celebrating the list.',
        payment: 150
      }

      const txHash = await account1.invoke(
          txTradeContract, 
          "init", 
          { 
            counterpart: account0.starknetContract.address, 
            agreementTerms: strToFeltArr(JSON.stringify(tradeInfo)),
            tokens: [txFlowContract.address]
          },
          { maxFee: FEE}
        )

      let txReceipt = await starknet.getTransactionReceipt(txHash)
      let tokenId = txReceipt['events'][0]['data'][3]
      tradeId = Number(parseInt(tokenId, 16))
      console.log('tokenId', tradeId, tokenId)
    }
    catch(mess){
      console.log(mess)
    }
  })

  it("agree txDeal correct", async function() {   
    
    const txHash = await account0.invoke(
        txTradeContract, 
        "agree", 
        { 
          tokenId: to_uint(BigInt(tradeId))
        },
        { maxFee: FEE}
      )
  })

  it("ratings before", async function() {   

    const data0 = await account0.call(txDharmaContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txDharmaContract, "balanceOf", { account: account1.starknetContract.address })
    
    let b0 = from_uint(data0.balance)
    let b1 = from_uint(data1.balance)

    console.log('dharma 0', b0)
    console.log('dharma 1', b1)
  })

  it("rate counterpart 1", async function() {  
    
    const txHash = await account0.invoke(
        txTradeContract, 
        "rate", 
        { 
          tokenId: to_uint(BigInt(tradeId)),
          rating:  to_uint(1n)
        },
        { maxFee: FEE}
      )
  })

  it("rate counterpart 2", async function() {   
    
    const txHash = await account1.invoke(
        txTradeContract, 
        "rate", 
        { 
          tokenId: to_uint(BigInt(tradeId)),
          rating:  to_uint(1n)
        },
        { maxFee: FEE}
      )
  })

  it("unauthorise mint of Dharma", async function() {   
    try{
      const txHash = await account1.invoke(
          txDharmaContract, 
          "mint", 
          { 
            to: account1.starknetContract.address,
            rating:  to_uint(1n)
          },
          { maxFee: FEE}
        )

        throw new Error('Should have failed')
    }
    catch(mess){
    }
  })

  it("ratings after", async function() {   
    let tokenId = to_uint(0n)

    const data0 = await account0.call(txDharmaContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txDharmaContract, "balanceOf", { account: account1.starknetContract.address })
    
    let b0 = from_uint(data0.balance)
    let b1 = from_uint(data1.balance)

    console.log('dharma 0', b0)
    console.log('dharma 1', b1)
  })

  it("total_supply", async function() {   
    const data = await account0.call(txFlowContract, "totalSupply")

    console.log('total supply', from_uint(data.totalSupply))
  })

  it("balance", async function() {   
    let tokenId = to_uint(0n)

    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txTradeContract.address, tokenId: tokenId})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })

    let b0 = from_uint(data0.balance)
    let b1 = from_uint(data1.balance)
    let bn = from_uint(datan.balance)
    let bc = from_uint(datac.balance)

    console.log('balance 0', b0)
    console.log('balance 1', b1)
    console.log('balance n', bn)
    console.log('balance c', bc)
    
    console.log('total', b0 + b1 + bc + bn)
  })

  it("transfer 0 -> 1", async function() {   
    try{
      const data = await account0.invoke(
          txFlowContract, 
          "transfer", 
          { recipient: account1.starknetContract.address, amount: to_uint(1n) },
          { maxFee: FEE}
        )

      console.log('transfer 0 -> 1', data)
    }
    catch(mess){
      console.log(mess)
    }
  })

  it("balance", async function() {   
    let tokenId = to_uint(0n)

    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txTradeContract.address, tokenId: tokenId})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })

    let b0 = from_uint(data0.balance)
    let b1 = from_uint(data1.balance)
    let bn = from_uint(datan.balance)
    let bc = from_uint(datac.balance)

    console.log('balance 0', b0)
    console.log('balance 1', b1)
    console.log('balance n', bn)
    console.log('balance c', bc)
    
    console.log('total', b0 + b1 + bc + bn)
  })

  it("states", async function() {   
    const {block_number: block, block_timestamp: time} = await account1.call(txFlowContract, "state")

    // let caller_address = '0x0' + toBN(caller).toString(16)
    let block_number = Number(block)
    let block_timestamp = new Date(Number(time) * 1000)

    console.log('states', { block_number: block_number, block_timestamp: block_timestamp })
  })
  
  it("add payment stream 1", async function() {   
    const amount = to_uint(BigInt('1'.replace(/,/g, '')) * ETH_WEI)
    await account0.invoke(
        txFlowContract, 
        'approve', 
        { spender: txFlowContract.address, amount: amount}, 
        { maxFee: FEE}
      )

    const {block_number: block, block_timestamp: time} = await account0.call(txFlowContract, "state")

    let block_timestamp = new Date(Number(time) * 1000)
    let maturity_timestamp = new Date(block_timestamp)
    maturity_timestamp.setMinutes(block_timestamp.getMinutes() + 150)
    let maturity_unixtime = Math.floor(maturity_timestamp.getTime() / 1000)

    let tokenId = to_uint(BigInt(tradeId))
    
    let txHash = await account0.invoke(
          txFlowContract, 
          "addNFTMaturityStream", 
          { beneficiary_address: txTradeContract.address, beneficiary_tokenId: tokenId, amount: amount, maturity: maturity_unixtime }, 
          { maxFee: FEE}
        )

    console.log('Tx: ', txHash)
    let txReceipt = await starknet.getTransactionReceipt(txHash)
    let _txData = txReceipt['events'][0]['data']
    let txData = {
      from_address: _txData[0],
      amount: from_uint({ low: parseInt(_txData[1], 16), high: parseInt(_txData[2], 16)}),
      count: Number(parseInt(_txData[3], 16)),
      start_time: new Date(Number(parseInt(_txData[4], 16)) * 1000),
      last_reset_time: new Date(Number(parseInt(_txData[5], 16)) * 1000),
      maturity_time: new Date(Number(parseInt(_txData[6], 16)) * 1000),
    }
    console.log('Tx Receipt', txData)    
  })


  it("add payment stream 2", async function() {
    const amount = to_uint(BigInt('2'.replace(/,/g, '')) * ETH_WEI)
    await account0.invoke(
        txFlowContract, 
        'approve', 
        { spender: txFlowContract.address, amount: amount}, 
        { maxFee: FEE}
      )
    
    const {block_number: block, block_timestamp: time} = await account0.call(txFlowContract, "state")

    let block_timestamp = new Date(Number(time) * 1000)
    let maturity_timestamp = new Date(block_timestamp)
    maturity_timestamp.setMinutes(block_timestamp.getMinutes() + 200)
    let maturity_unixtime = Math.floor(maturity_timestamp.getTime() / 1000)

    let tokenId = to_uint(BigInt(tradeId))
    
    let txHash = await account0.invoke(
        txFlowContract, 
        "addNFTMaturityStream", 
        { beneficiary_address: txTradeContract.address, beneficiary_tokenId: tokenId, amount: amount, maturity: maturity_unixtime }, 
        { maxFee: FEE}
      )
    console.log('Tx: ', txHash)
    let txReceipt = await starknet.getTransactionReceipt(txHash)
    let len = txReceipt['events'].length
    for (let i = 0; i < len; i++){
      let _txData = txReceipt['events'][i]['data']
      let txData = {
        from_address: _txData[0],
        amount: from_uint({ low: parseInt(_txData[1], 16), high: parseInt(_txData[2], 16)}),
        count: Number(parseInt(_txData[3], 16)),
        start_time: new Date(Number(parseInt(_txData[4], 16)) * 1000),
        last_reset_time: new Date(Number(parseInt(_txData[5], 16)) * 1000),
        maturity_time: new Date(Number(parseInt(_txData[6], 16)) * 1000),
      }
      console.log('Tx Receipt', txData)    
    }
  })

  it("balance", async function() {   
    let tokenId = to_uint(BigInt(tradeId))

    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txTradeContract.address, tokenId: tokenId})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })

    let b0 = from_uint(data0.balance)
    let b1 = from_uint(data1.balance)
    let bn = from_uint(datan.balance)
    let bc = from_uint(datac.balance)

    console.log('balance 0', b0)
    console.log('balance 1', b1)
    console.log('balance n', bn)
    console.log('balance c', bc)
    
    console.log('total', b0 + b1 + bc + bn)
  })

  it("balance", async function() {   
    let tokenId = to_uint(BigInt(tradeId))

    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txTradeContract.address, tokenId: tokenId})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })

    let b0 = from_uint(data0.balance)
    let b1 = from_uint(data1.balance)
    let bn = from_uint(datan.balance)
    let bc = from_uint(datac.balance)

    console.log('balance 0', b0)
    console.log('balance 1', b1)
    console.log('balance n', bn)
    console.log('balance c', bc)
    
    console.log('total', b0 + b1 + bc + bn)
  })

  it("get before locked out payment stream", async function() {   
    
    const amount = await account0.call(txFlowContract, "lockedOut", { payer_address: account0.address })
    console.log('locked amount', {locked_amount: from_uint(amount.locked_amount), block_timestamp: new Date(Number(amount.block_timestamp) * 1000)})
  })

  it("get correct payment stream", async function() {   
    let tokenId = to_uint(BigInt(tradeId))
    const amount = await account1.call(txFlowContract, "withdrawAmountNFT", { beneficiary_address: txTradeContract.address, beneficiary_tokenId: tokenId })
    console.log('can withdraw', {available_amount: from_uint(amount.available_amount), locked_amount: from_uint(amount.locked_amount), block_timestamp: new Date(Number(amount.block_timestamp) * 1000)})
  })


  it("withdraw", async function() {
    // try{
      let tokenId = to_uint(BigInt(tradeId))
      let txHash = await account1.invoke(
          txFlowContract, 
          "withdrawNFT", 
          { beneficiary_address: txTradeContract.address, beneficiary_tokenId: tokenId }, 
          { maxFee: FEE}
        )
      console.log('Tx:', txHash)
      let txReceipt = await starknet.getTransactionReceipt(txHash)
      let len = txReceipt['events'].length
      for (let i = 0; i < len; i++){
        let _txData = txReceipt['events'][i]['data']
        
        let txData = {
          from_address: _txData[0],
          amount: from_uint({ low: parseInt(_txData[1], 16), high: parseInt(_txData[2], 16)}),
          locked_amount: from_uint({ low: parseInt(_txData[3], 16), high: parseInt(_txData[4], 16)}),
          initial_amount: from_uint({ low: parseInt(_txData[5], 16), high: parseInt(_txData[6], 16)}),

          start_time: new Date(Number(parseInt(_txData[7], 16)) * 1000),
          maturity_time: new Date(Number(parseInt(_txData[8], 16)) * 1000),
          block_time: new Date(Number(parseInt(_txData[9], 16)) * 1000)
        }
        console.log('widraw', i, txData)
      }
    // } catch (err: any) {
    //   console.log("nothing to withdraw")
    // }
  })

  it("withdraw wrong address", async function() {
    try{
      let tokenId = to_uint(BigInt(tradeId))
      let txHash = await account0.invoke(
          txFlowContract, 
          "withdrawNFT", 
          { beneficiary_address: txTradeContract.address, beneficiary_tokenId: tokenId }, 
          { maxFee: FEE}
        )
      console.log('Tx:', txHash)
      let txReceipt = await starknet.getTransactionReceipt(txHash)
      let len = txReceipt['events'].length
      for (let i = 0; i < len; i++){
        let _txData = txReceipt['events'][i]['data']
        
        let txData = {
          from_address: _txData[0],
          amount: from_uint({ low: parseInt(_txData[1], 16), high: parseInt(_txData[2], 16)}),
          locked_amount: from_uint({ low: parseInt(_txData[3], 16), high: parseInt(_txData[4], 16)}),
          initial_amount: from_uint({ low: parseInt(_txData[5], 16), high: parseInt(_txData[6], 16)}),

          start_time: new Date(Number(parseInt(_txData[7], 16)) * 1000),
          maturity_time: new Date(Number(parseInt(_txData[8], 16)) * 1000),
          block_time: new Date(Number(parseInt(_txData[9], 16)) * 1000)
        }
        console.log('widraw', i, txData)
      }

      throw new Error('should have failed')
    } catch (err: any) {
    }
  })

  it("get after locked out payment stream", async function() {   
    
    const amount = await account0.call(txFlowContract, "lockedOut", { payer_address: account0.address })
    console.log('locked amount', {locked_amount: from_uint(amount.locked_amount), block_timestamp: new Date(Number(amount.block_timestamp) * 1000)})
  })

  it("balance", async function() {   
    let tokenId = to_uint(BigInt(tradeId))

    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txTradeContract.address, tokenId: tokenId})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })

    let b0 = from_uint(data0.balance)
    let b1 = from_uint(data1.balance)
    let bn = from_uint(datan.balance)
    let bc = from_uint(datac.balance)

    console.log('balance 0', b0)
    console.log('balance 1', b1)
    console.log('balance n', bn)
    console.log('balance c', bc)
    
    console.log('total', b0 + b1 + bc + bn)
  })
});
