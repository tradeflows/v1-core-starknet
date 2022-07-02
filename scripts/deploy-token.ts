import hardhat from "hardhat";
import { toUint256WithFelts } from "../scripts/starknetUtils"
import { walletAddressOwner, walletPrivateOwner, ETH_WEI } from "../scripts/constants";

  
async function main() {
    console.log('TradeFlows deploying token test contracts...')

    const owner = (await hardhat.starknet.getAccountFromAddress(walletAddressOwner, walletPrivateOwner, 'OpenZeppelin'))

    const total_supply = BigInt('1,000,000,000,000'.replace(/,/g, '')) * ETH_WEI

    const erc20ContractFactory = await hardhat.starknet.getContractFactory('openzeppelin/token/erc20/ERC20')
    const erc20Contract = await erc20ContractFactory.deploy({
      name: hardhat.starknet.shortStringToBigInt('ERC20 Test'),
      symbol: hardhat.starknet.shortStringToBigInt('T20'),
      decimals: 18,
      initial_supply: toUint256WithFelts(total_supply.toString()),
      recipient: owner.starknetContract.address
    })

    const txFlowContractFactory = await hardhat.starknet.getContractFactory('tradeflows/txFlow')
    const txFlowContract = await txFlowContractFactory.deploy({
        name: hardhat.starknet.shortStringToBigInt('ERC20 Test txFlow'),
        symbol: hardhat.starknet.shortStringToBigInt('T20xFlow'),
        baseToken: erc20Contract.address
    })

    console.log('ERC20:           ', erc20Contract.address)
    console.log('Flow:            ', txFlowContract.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
