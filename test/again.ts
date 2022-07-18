import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory, Account } from "hardhat/types/runtime";
import { TIMEOUT, FEE, WEIGHT_BASE, ETH_WEI, walletAddressOwner, walletPrivateOwner, walletAddress0, walletPrivate0, walletAddress1, walletPrivate1, txFlowContractAddress, txAssetContractAddress, txDharmaContractAddress, erc20ContractAddress, daoContractAddress } from "../scripts/constants";
import { strToFeltArr, toUint256WithFelts, fromUint256WithFelts } from "../scripts/starknetUtils"

describe("Run Workflow Again", function () {
  this.timeout(TIMEOUT);

  let erc20ContractFactory: StarknetContractFactory;
  let erc20Contract: StarknetContract;
  let txFlowContractFactory: StarknetContractFactory;
  let txFlowContract: StarknetContract;
  let txFlowContract_no: StarknetContract;
  let txAssetContractFactory: StarknetContractFactory;
  let txAssetContract: StarknetContract;
  let txDharmaContractFactory: StarknetContractFactory;
  let txDharmaContract: StarknetContract;
  let daoContractFactory: StarknetContractFactory;
  let daoContract: StarknetContract;
  
  let owner: Account;
  let account0: Account;
  let account1: Account;

  let tokenId: Number;

  
  before(async function() {

    owner = (await starknet.getAccountFromAddress(walletAddressOwner, walletPrivateOwner, 'OpenZeppelin'))
    account0 = (await starknet.getAccountFromAddress(walletAddress0, walletPrivate0, 'OpenZeppelin'))
    account1 = (await starknet.getAccountFromAddress(walletAddress1, walletPrivate1, 'OpenZeppelin'))
    
    console.log('Account 0 address: ', account0.starknetContract.address, account0.publicKey, account0.privateKey)
    console.log('Account 1 address: ', account1.starknetContract.address, account1.publicKey, account1.privateKey)

    daoContractFactory = await starknet.getContractFactory('tradeflows/DAO')
    txFlowContractFactory = await starknet.getContractFactory('tradeflows/txFlow')
    txDharmaContractFactory = await starknet.getContractFactory('tradeflows/txDharma')
    txAssetContractFactory = await starknet.getContractFactory('tradeflows/txAsset')
    erc20ContractFactory = await starknet.getContractFactory('openzeppelin/token/erc20/ERC20')
    
    daoContract = await daoContractFactory.getContractAt(daoContractAddress)
    txFlowContract = await txFlowContractFactory.getContractAt(txFlowContractAddress)
    txDharmaContract = await txDharmaContractFactory.getContractAt(txDharmaContractAddress)
    txAssetContract = await txAssetContractFactory.getContractAt(txAssetContractAddress)
    erc20Contract = await erc20ContractFactory.getContractAt(erc20ContractAddress)
    
    console.log("DAO: ", daoContract.address)
    console.log("USDC: ", erc20Contract.address)
    console.log("txFlow: ", txFlowContract.address)
    console.log("txDharma: ", txDharmaContract.address)
    console.log("txAsset: ", txAssetContract.address)
    // console.log("txFlow NO: ", txFlowContract_no.address)
    
  })

  it("states", async function() {   
    const {block_number: block, block_timestamp: time} = await account0.call(txFlowContract, "state")

    let block_number = Number(block)
    let block_timestamp = new Date(Number(time) * 1000)

    console.log('states', { block_number: block_number, block_timestamp: block_timestamp })
  })

  it("balance", async function() {   
    let tokenId = toUint256WithFelts("0")

    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txAssetContract.address, tokenId: tokenId})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })
    const datad = await account0.call(txFlowContract, "balanceOf", { account: daoContract.address })

    let b0 = (fromUint256WithFelts(data0.balance).toString())
    let b1 = (fromUint256WithFelts(data1.balance).toString())
    let bn = (fromUint256WithFelts(datan.balance).toString())
    let bc = (fromUint256WithFelts(datac.balance).toString())
    let bd = (fromUint256WithFelts(datad.balance).toString())

    console.log('balance account 0', b0)
    console.log('balance account 1', b1)
    console.log('balance nft      ', bn)
    console.log('balance escrow   ', bc)
    console.log('balance dao      ', bd)
    
    console.log('total', (BigInt(b0) + BigInt(b1) + BigInt(bn) + BigInt(bc) + BigInt(bd)).toString())
  })

  it("balance erc20", async function() {   
    const data0 = await account0.call(erc20Contract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(erc20Contract, "balanceOf", { account: account1.starknetContract.address })
    const datac = await account0.call(erc20Contract, "balanceOf", { account: txFlowContract.address })

    let b0 = fromUint256WithFelts(data0.balance).toString()
    let b1 = fromUint256WithFelts(data1.balance).toString()
    let bc = fromUint256WithFelts(datac.balance).toString()

    console.log('balance 0', b0)
    console.log('balance 1', b1)
    console.log('balance c', bc)
  })

  it("transfer 0 -> 1", async function() {   
    const data = await account0.invoke(
        txFlowContract, 
        "transfer", 
        { recipient: account1.starknetContract.address, amount: toUint256WithFelts("10") },
        { maxFee: FEE}
      )

    console.log('transfer 0 -> 1', data)
  })

  it("init txAsset", async function() {   
    let tradeInfo = {
      counterPart: 'John Doe',
      description: 'I hope that a study of very long sentences will arm you with strategies that are almost as diverse as the sentences themselves, such as: starting each clause with the same word, tilting with dependent clauses toward a revelation at the end, padding with parentheticals, showing great latitude toward standard punctuation, rabbit-trailing away from the initial subject, encapsulating an entire life, and lastly, as this sentence is, celebrating the list.',
      payments: [
        {
          amount: 100,
          collateral: 10,
          type: 'stream',
          startDate: '2022-12-12',
          endDate: '2023-12-12'
        },
        {
          amount: 100,
          collateral: 10,
          type: 'stream',
          startDate: '2023-12-12',
          endDate: '2024-12-12'
        },
        {
          amount: 100,
          collateral: 10,
          type: 'bullet',
          date: '2024-12-12'
        }
        
      ]
    }

    await account1.invoke(
      txFlowContract, 
      'approve', 
      { spender: txAssetContract.address, amount: toUint256WithFelts("5") }, 
      { maxFee: FEE}
    )

    const txHash = await account1.invoke(
        txAssetContract, 
        "init", 
        { 
          counterpart: account0.starknetContract.address, 
          meta: strToFeltArr(JSON.stringify(tradeInfo)),
          tokens: [txFlowContract.address],
          members: [account1.starknetContract.address],
          weights: [WEIGHT_BASE]
        },
        { maxFee: FEE}
      )

    let txReceipt = await starknet.getTransactionReceipt(txHash)
    tokenId = Number(fromUint256WithFelts({ low: BigInt(txReceipt['events'][0]['data'][0]), high: BigInt(txReceipt['events'][0]['data'][1]) }).toString())
    console.log('tokenId', tokenId.toString())
  })

  it("agree txDeal correct", async function() {   
    console.log('agree to:', tokenId.toString())
    const txHash = await account0.invoke(
        txAssetContract, 
        "agree", 
        { 
          tokenId: toUint256WithFelts(tokenId.toString())
        },
        { maxFee: FEE}
      )
  })

  it("add payment stream 1", async function() {   
    const target_amount = toUint256WithFelts((BigInt('10,000'.replace(/,/g, ''))).toString())
    const initial_amount = toUint256WithFelts((BigInt('5,000'.replace(/,/g, ''))).toString())
    await account0.invoke(
        txFlowContract, 
        'approve', 
        { spender: txFlowContract.address, amount: initial_amount}, 
        { maxFee: FEE}
      )

    const {block_number: block, block_timestamp: time} = await account0.call(txFlowContract, "state")

    let block_timestamp = new Date(Number(time) * 1000)
    
    let start_timestamp = new Date(block_timestamp)
    let start_unixtime = Math.floor(start_timestamp.getTime() / 1000)

    let maturity_timestamp = start_timestamp
    maturity_timestamp.setMinutes(start_timestamp.getMinutes() + 35)
    let maturity_unixtime = Math.floor(maturity_timestamp.getTime() / 1000)

    let txHash = await account0.invoke(
          txFlowContract, 
          "addNFTMaturityStream", 
          { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()), target_amount: target_amount, initial_amount: initial_amount, start: start_unixtime, maturity: maturity_unixtime }, 
          { maxFee: FEE}
        )
    
    console.log('Tx: ', txHash)
    let txReceipt = await starknet.getTransactionReceipt(txHash)

    console.log('Flow ID: ', parseInt(txReceipt['events'][0]['data'][0], 16))
  })

  it("ratings before", async function() {   

    const data0 = await account0.call(txDharmaContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txDharmaContract, "balanceOf", { account: account1.starknetContract.address })
    
    let b0 = fromUint256WithFelts(data0.balance).toString()
    let b1 = fromUint256WithFelts(data1.balance).toString()

    console.log('dharma 0', b0)
    console.log('dharma 1', b1)
  })

  it("rate counterpart 1", async function() {  
    
    const txHash = await account0.invoke(
        txAssetContract, 
        "rate", 
        { 
          tokenId: toUint256WithFelts(tokenId.toString()),
          rating:  toUint256WithFelts("1")
        },
        { maxFee: FEE}
      )
  })

  it("rate counterpart 2", async function() {   
    
    const txHash = await account1.invoke(
        txAssetContract, 
        "rate", 
        { 
          tokenId: toUint256WithFelts(tokenId.toString()),
          rating:  toUint256WithFelts("1")
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
            rating:  toUint256WithFelts("1")
          },
          { maxFee: FEE}
        )

        throw new Error('Should have failed')
    }
    catch(mess){
    }
  })

  it("ratings after", async function() {   
    const data0 = await account0.call(txDharmaContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txDharmaContract, "balanceOf", { account: account1.starknetContract.address })
    
    let b0 = fromUint256WithFelts(data0.balance).toString()
    let b1 = fromUint256WithFelts(data1.balance).toString()

    console.log('dharma 0', b0)
    console.log('dharma 1', b1)
  })

  it("total_supply", async function() {   
    const data = await account0.call(txFlowContract, "totalSupply")

    console.log('total supply', fromUint256WithFelts(data.totalSupply))
  })

  it("balance", async function() {   
    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txAssetContract.address, tokenId: toUint256WithFelts(tokenId.toString())})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })
    const datad = await account0.call(txFlowContract, "balanceOf", { account: daoContract.address })

    let b0 = (fromUint256WithFelts(data0.balance).toString())
    let b1 = (fromUint256WithFelts(data1.balance).toString())
    let bn = (fromUint256WithFelts(datan.balance).toString())
    let bc = (fromUint256WithFelts(datac.balance).toString())
    let bd = (fromUint256WithFelts(datad.balance).toString())

    console.log('balance account 0', b0)
    console.log('balance account 1', b1)
    console.log('balance nft      ', bn)
    console.log('balance escrow   ', bc)
    console.log('balance dao      ', bd)
    
    console.log('total', (BigInt(b0) + BigInt(b1) + BigInt(bn) + BigInt(bc) + BigInt(bd)).toString())
  })

  it("states", async function() {   
    const {block_number: block, block_timestamp: time} = await account1.call(txFlowContract, "state")

    // let caller_address = '0x0' + toBN(caller).toString(16)
    let block_number = Number(block)
    let block_timestamp = new Date(Number(time) * 1000)

    console.log('states', { block_number: block_number, block_timestamp: block_timestamp })
  })
  
  it("add payment stream NO", async function() {

    try{
      const amount = toUint256WithFelts((BigInt('2'.replace(/,/g, '')) * ETH_WEI).toString())
      await account0.invoke(
          txFlowContract_no, 
          'approve', 
          { spender: txFlowContract_no.address, amount: amount}, 
          { maxFee: FEE}
        )
      
      const {block_number: block, block_timestamp: time} = await account0.call(txFlowContract, "state")

      let block_timestamp = new Date(Number(time) * 1000)

      let start_timestamp = new Date(block_timestamp)
      start_timestamp.setMinutes(block_timestamp.getMinutes())
      let start_unixtime = Math.floor(start_timestamp.getTime() / 1000)
  
      let maturity_timestamp = new Date(block_timestamp)
      maturity_timestamp.setMinutes(block_timestamp.getMinutes() + 20)
      let maturity_unixtime = Math.floor(maturity_timestamp.getTime() / 1000)

      let txHash = await account0.invoke(
          txFlowContract_no, 
          "addNFTMaturityStream", 
          { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()), target_amount: amount, initial_amount: amount, start: start_unixtime, maturity: maturity_unixtime }, 
          { maxFee: FEE}
        )
      console.log('Tx: ', txHash)
      let txReceipt = await starknet.getTransactionReceipt(txHash)
      let len = txReceipt['events'].length
      for (let i = 0; i < len; i++){
        let _txData = txReceipt['events'][i]['data']
        let txData = {
          from_address: _txData[0],
          amount: { low: parseInt(_txData[1], 16), high: parseInt(_txData[2], 16)},
          count: Number(parseInt(_txData[3], 16)),
          start_time: new Date(Number(parseInt(_txData[4], 16)) * 1000),
          last_reset_time: new Date(Number(parseInt(_txData[5], 16)) * 1000),
          maturity_time: new Date(Number(parseInt(_txData[6], 16)) * 1000),
        }
        console.log('Tx Receipt', txData)    
      }
      throw new Error('Should have failed')
    }
    catch(mess){
    }
  })

  it("add payment stream 2", async function() {   
    const amount = toUint256WithFelts((BigInt('1'.replace(/,/g, ''))).toString())
    await account0.invoke(
        txFlowContract, 
        'approve', 
        { spender: txFlowContract.address, amount: amount}, 
        { maxFee: FEE}
      )

    const {block_number: block, block_timestamp: time} = await account0.call(txFlowContract, "state")

    let block_timestamp = new Date(Number(time) * 1000)
    
    let start_timestamp = new Date(block_timestamp)
    start_timestamp.setMinutes(block_timestamp.getMinutes())
    let start_unixtime = Math.floor(start_timestamp.getTime() / 1000)

    let maturity_timestamp = new Date(block_timestamp)
    maturity_timestamp.setMinutes(block_timestamp.getMinutes() + 15000)
    let maturity_unixtime = Math.floor(maturity_timestamp.getTime() / 1000)

    
    let txHash = await account0.invoke(
          txFlowContract, 
          "addNFTMaturityStream", 
          { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()), target_amount: amount, initial_amount: amount, start: start_unixtime, maturity: maturity_unixtime }, 
          { maxFee: FEE}
        )

    console.log('Tx: ', txHash)
    let txReceipt = await starknet.getTransactionReceipt(txHash)
    console.log('Flow ID: ', parseInt(txReceipt['events'][0]['data'][0], 16))
  })

  it("increase amount", async function() {   
    const initial_amount = toUint256WithFelts((BigInt('1,000'.replace(/,/g, ''))).toString())

    await account0.invoke(
      txFlowContract, 
      'approve', 
      { spender: txFlowContract.address, amount: initial_amount}, 
      { maxFee: FEE}
    )

    await account0.invoke(
        txFlowContract, 
        'increaseAmount', 
        { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()), id: 0, amount: initial_amount }, 
        { maxFee: FEE}
      )
  })

  it("balance", async function() {   
    
    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txAssetContract.address, tokenId: toUint256WithFelts(tokenId.toString())})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })
    const datad = await account0.call(txFlowContract, "balanceOf", { account: daoContract.address })

    let b0 = (fromUint256WithFelts(data0.balance).toString())
    let b1 = (fromUint256WithFelts(data1.balance).toString())
    let bn = (fromUint256WithFelts(datan.balance).toString())
    let bc = (fromUint256WithFelts(datac.balance).toString())
    let bd = (fromUint256WithFelts(datad.balance).toString())

    console.log('balance account 0', b0)
    console.log('balance account 1', b1)
    console.log('balance nft      ', bn)
    console.log('balance escrow   ', bc)
    console.log('balance dao      ', bd)
    
    console.log('total', (BigInt(b0) + BigInt(b1) + BigInt(bn) + BigInt(bc) + BigInt(bd)).toString())
  })

  it("get before locked out payment stream", async function() {   
    
    const amount = await account0.call(txFlowContract, "lockedOut", { payer_address: account0.address })
    console.log('locked amount', {locked_amount: fromUint256WithFelts(amount.locked_amount).toString(), block_timestamp: new Date(Number(amount.block_timestamp) * 1000)})
  })

  it("get correct payment stream", async function() {   
    const amount = await account1.call(txFlowContract, "withdrawAmountNFT", { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()) })
    console.log('can withdraw', {available_amount: fromUint256WithFelts(amount.available_amount).toString(), locked_amount: fromUint256WithFelts(amount.locked_amount).toString(), block_timestamp: new Date(Number(amount.block_timestamp) * 1000)})
  })

  it("withdraw", async function() {
    let txHash = await account1.invoke(
        txFlowContract, 
        "withdrawNFT", 
        { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()) }, 
        { maxFee: FEE}
      )
    console.log('Tx:', txHash)
    let txReceipt = await starknet.getTransactionReceipt(txHash)
    console.log('Tx:', txHash)
  })

  it("balance", async function() {   
    
    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txAssetContract.address, tokenId: toUint256WithFelts(tokenId.toString())})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })
    const datad = await account0.call(txFlowContract, "balanceOf", { account: daoContract.address })

    let b0 = (fromUint256WithFelts(data0.balance).toString())
    let b1 = (fromUint256WithFelts(data1.balance).toString())
    let bn = (fromUint256WithFelts(datan.balance).toString())
    let bc = (fromUint256WithFelts(datac.balance).toString())
    let bd = (fromUint256WithFelts(datad.balance).toString())

    console.log('balance account 0', b0)
    console.log('balance account 1', b1)
    console.log('balance nft      ', bn)
    console.log('balance escrow   ', bc)
    console.log('balance dao      ', bd)
    
    console.log('total', (BigInt(b0) + BigInt(b1) + BigInt(bn) + BigInt(bc) + BigInt(bd)).toString())
  })


  it("withdraw", async function() {
    let txHash = await account1.invoke(
        txFlowContract, 
        "withdrawNFT", 
        { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()) }, 
        { maxFee: FEE}
      )

    let txReceipt = await starknet.getTransactionReceipt(txHash)
    console.log('Tx:', txHash)
  })

  it("withdraw wrong address", async function() {
    try{
      let txHash = await account0.invoke(
          txFlowContract, 
          "withdrawNFT", 
          { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()) }, 
          { maxFee: FEE}
        )
      console.log('Tx:', txHash)
      let txReceipt = await starknet.getTransactionReceipt(txHash)
      let len = txReceipt['events'].length
      for (let i = 0; i < len; i++){
        let _txData = txReceipt['events'][i]['data']
        
        let txData = {
          from_address: _txData[0],
          amount: ({ low: parseInt(_txData[1], 16), high: parseInt(_txData[2], 16)}),
          locked_amount: ({ low: parseInt(_txData[3], 16), high: parseInt(_txData[4], 16)}),
          initial_amount: ({ low: parseInt(_txData[5], 16), high: parseInt(_txData[6], 16)}),

          start_time: new Date(Number(parseInt(_txData[7], 16)) * 1000),
          maturity_time: new Date(Number(parseInt(_txData[8], 16)) * 1000),
          block_time: new Date(Number(parseInt(_txData[9], 16)) * 1000)
        }
        console.log('withdraw', i, txData)
      }

      throw new Error('should have failed')
    } catch (err: any) {
    }
  })

  it("get after locked out payment stream", async function() {   
    
    const amount = await account0.call(txFlowContract, "lockedOut", { payer_address: account0.address })
    console.log('locked amount', {locked_amount: fromUint256WithFelts(amount.locked_amount).toString(), block_timestamp: new Date(Number(amount.block_timestamp) * 1000)})
  })

  it("balance", async function() {   
    
    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txAssetContract.address, tokenId: toUint256WithFelts(tokenId.toString())})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })
    const datad = await account0.call(txFlowContract, "balanceOf", { account: daoContract.address })

    let b0 = (fromUint256WithFelts(data0.balance).toString())
    let b1 = (fromUint256WithFelts(data1.balance).toString())
    let bn = (fromUint256WithFelts(datan.balance).toString())
    let bc = (fromUint256WithFelts(datac.balance).toString())
    let bd = (fromUint256WithFelts(datad.balance).toString())

    console.log('balance account 0', b0)
    console.log('balance account 1', b1)
    console.log('balance nft      ', bn)
    console.log('balance escrow   ', bc)
    console.log('balance dao      ', bd)
    
    console.log('total', (BigInt(b0) + BigInt(b1) + BigInt(bn) + BigInt(bc) + BigInt(bd)).toString())
  })

  it("pause", async function() {   
    
    await account0.invoke(
        txFlowContract, 
        'pause', 
        { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()), pause: 1 }, 
        { maxFee: FEE}
      )
  })

  it("pause", async function() {   
    await account1.invoke(
        txFlowContract, 
        'pause', 
        { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()), pause: 1 }, 
        { maxFee: FEE}
      )
  })
 

  it("balance", async function() {   
    
    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txAssetContract.address, tokenId: toUint256WithFelts(tokenId.toString())})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })
    const datad = await account0.call(txFlowContract, "balanceOf", { account: daoContract.address })

    let b0 = (fromUint256WithFelts(data0.balance).toString())
    let b1 = (fromUint256WithFelts(data1.balance).toString())
    let bn = (fromUint256WithFelts(datan.balance).toString())
    let bc = (fromUint256WithFelts(datac.balance).toString())
    let bd = (fromUint256WithFelts(datad.balance).toString())

    console.log('balance account 0', b0)
    console.log('balance account 1', b1)
    console.log('balance nft      ', bn)
    console.log('balance escrow   ', bc)
    console.log('balance dao      ', bd)
    
    console.log('total', (BigInt(b0) + BigInt(b1) + BigInt(bn) + BigInt(bc) + BigInt(bd)).toString())
  })

  it("decrease amount", async function() {   
    const initial_amount = toUint256WithFelts((BigInt('500'.replace(/,/g, ''))).toString())


    await account0.invoke(
        txFlowContract, 
        'decreaseAmount', 
        { beneficiary_address: txAssetContract.address, beneficiary_tokenId: toUint256WithFelts(tokenId.toString()), id: 0, amount: initial_amount }, 
        { maxFee: FEE}
      )
  })

  it("balance erc20", async function() {   
    const data0 = await account0.call(erc20Contract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(erc20Contract, "balanceOf", { account: account1.starknetContract.address })
    const datac = await account0.call(erc20Contract, "balanceOf", { account: txFlowContract.address })

    let b0 = fromUint256WithFelts(data0.balance).toString()
    let b1 = fromUint256WithFelts(data1.balance).toString()
    let bc = fromUint256WithFelts(datac.balance).toString()

    console.log('balance 0', b0)
    console.log('balance 1', b1)
    console.log('balance c', bc)
  })

  it("withdraw from flow to base to", async function() {   
    const amount = toUint256WithFelts("1")

    const txHash = await account1.invoke(
      txFlowContract, 
        "withdrawBase", 
        { 
          amount: amount
        },
        { maxFee: FEE}
      )
  })

  it("balance erc20", async function() {   
    const data0 = await account0.call(erc20Contract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(erc20Contract, "balanceOf", { account: account1.starknetContract.address })
    const datac = await account0.call(erc20Contract, "balanceOf", { account: txFlowContract.address })

    let b0 = fromUint256WithFelts(data0.balance).toString()
    let b1 = fromUint256WithFelts(data1.balance).toString()
    let bc = fromUint256WithFelts(datac.balance).toString()

    console.log('balance 0', b0)
    console.log('balance 1', b1)
    console.log('balance c', bc)
  })

  it("balance", async function() {   
    
    const data0 = await account0.call(txFlowContract, "balanceOf", { account: account0.starknetContract.address })
    const data1 = await account0.call(txFlowContract, "balanceOf", { account: account1.starknetContract.address })
    const datan = await account0.call(txFlowContract, "balanceOfNFT", { account: txAssetContract.address, tokenId: toUint256WithFelts(tokenId.toString())})
    const datac = await account0.call(txFlowContract, "balanceOf", { account: txFlowContract.address })
    const datad = await account0.call(txFlowContract, "balanceOf", { account: daoContract.address })

    let b0 = (fromUint256WithFelts(data0.balance).toString())
    let b1 = (fromUint256WithFelts(data1.balance).toString())
    let bn = (fromUint256WithFelts(datan.balance).toString())
    let bc = (fromUint256WithFelts(datac.balance).toString())
    let bd = (fromUint256WithFelts(datad.balance).toString())

    console.log('balance account 0', b0)
    console.log('balance account 1', b1)
    console.log('balance nft      ', bn)
    console.log('balance escrow   ', bc)
    console.log('balance dao      ', bd)
    
    console.log('total', (BigInt(b0) + BigInt(b1) + BigInt(bn) + BigInt(bc) + BigInt(bd)).toString())
  })
});
