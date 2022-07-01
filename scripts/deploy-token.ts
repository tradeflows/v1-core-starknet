import hardhat from "hardhat";
import { toUint256WithFelts } from "../scripts/starknetUtils"
import { walletAddressOwner, walletPrivateOwner, ETH_WEI } from "../scripts/constants";

  
async function main() {
    const contractFactory = await hardhat.starknet.getContractFactory("contract");
    const contract = await contractFactory.deploy({ initial_balance: 0 });
    console.log("Deployed to:", contract.address);

    const owner = (await hardhat.starknet.getAccountFromAddress(walletAddressOwner, walletPrivateOwner, 'OpenZeppelin'))

    const total_supply = BigInt('1,000,000,000,000'.replace(/,/g, '')) * ETH_WEI

    const txFlowContractFactory = await hardhat.starknet.getContractFactory('tradeflows/txFlow')
    const txFlowContract = await txFlowContractFactory.deploy({
      name: hardhat.starknet.shortStringToBigInt('USDC txFlow'),
      symbol: hardhat.starknet.shortStringToBigInt('USDCxFlow'),
      decimals: 18,
      initial_supply: toUint256WithFelts(total_supply.toString()),
      recipient: owner.starknetContract.address
    })
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
