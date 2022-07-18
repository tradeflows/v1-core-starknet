import hardhat from "hardhat";
import { toUint256WithFelts } from "../scripts/starknetUtils"
import { ETH_WEI } from "../scripts/constants";

async function main() {
    console.log('TradeFlows deploying infrastructure contracts...')
    const owner = (await hardhat.starknet.deployAccount("OpenZeppelin"))

    const total_supply = BigInt('1,000,000,000,000'.replace(/,/g, '')) * ETH_WEI

    const daoContractFactory = await hardhat.starknet.getContractFactory('tradeflows/DAO')
    const daoContract = await daoContractFactory.deploy({
      name: hardhat.starknet.shortStringToBigInt('TradeFlows DAO'),
      symbol: hardhat.starknet.shortStringToBigInt('DAO'),
      decimals: 18,
      initial_supply: toUint256WithFelts(total_supply.toString()),
      recipient: owner.starknetContract.address
    })

    const txDharmaContractFactory = await hardhat.starknet.getContractFactory('tradeflows/txDharma')
    const txDharmaContract = await txDharmaContractFactory.deploy({
      name: hardhat.starknet.shortStringToBigInt('txDharma Contract'),
      symbol: hardhat.starknet.shortStringToBigInt('txDharma'),
      decimals: 18,
      owner: owner.starknetContract.address
    })
    
    const txAssetContractFactory = await hardhat.starknet.getContractFactory('tradeflows/txAsset')
    const txAssetContract = await txAssetContractFactory.deploy({
      name: hardhat.starknet.shortStringToBigInt('TradeFlows Deal NFT'),
      symbol: hardhat.starknet.shortStringToBigInt('txAsset'),
      owner: owner.starknetContract.address,
      txDharma_address: txDharmaContract.address,
      dao_address: daoContract.address
    })

    console.log('Owner Address: ', owner.starknetContract.address)
    console.log('      Public:  ', owner.publicKey)
    console.log('      Private: ', owner.privateKey)
    console.log('DAO:           ', daoContract.address)
    console.log('txDharma:      ', txDharmaContract.address)
    console.log('txAsset:       ', txAssetContract.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
