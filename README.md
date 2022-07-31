# TradeFlows Core Protocol - Hardhat Project

<p align="center">
  <img width="300" src="assets/tradeflows.png" />
</p>


[TradeFlows Core](http://www.tradeflows.io) is a decentralised Commerce Protocol on [StarkNet](https://starkware.co/starknet/). Our goal is to provide a set of on-chain tools that allow our community to to build the best commercial experiences between each other in a collaborative, transparent, permissionless and trustless manner. 

For a more indepth discussion about the TradeFlows DAO, please refer to our [GitBook page](https://tradeflows-dao.gitbook.io/tradeflows-documentation/).

We are very proud to have received a grant from the Starkware!

<p align="center">
  <img width="200" src="assets/StarkNet_logo.png" />
</p>

Please give us a GitHub Star 🌟 Above if you like this project. We are actively looking for contributors so please reach out to us if you are interested.

Current commercial relationships use archaic methods to interact. PDFs, digital signature, emails and bank transfers plague the workflows currently used by people when engaging commercially. The lack of structure is a culprit for countless operational errors, uncertainty and high costs. TradeFlows aims to solve by offering a platform that allows people to build structure and certainty to workflows in all industrys. 

Furthermore, current / centralised commercial workflows are: 
- Uncertain
- Opaque
- Slow; and 
- Costly

These factor have very adverse effects on global supply chains of both goods and services including an increase in the need and cost of financing due to this uncertainty.

Blockchain is able to mitigate all four negative effects using Smart Contracts that enable a sellers to:
- Describe an asset's conditions and payment terms;
- Mint an NFT that represents the asset;
- Compose NFTs to represent multi-layer structured asset;
- Allows the buyer to agree to the asset on-chain through custom NFT functionality;
- The buyer can then link payment streams to the NFT;
- Collateralise the payment streams in order to show an availability of funds without losing control over them. The seller knows that as long as the funds are in the self-custody contract, they will only be used to pay the stream;
- Rate each other while there is a asset alive through a non-transferable ERC20 token. This offers a high social rating with a degree of integrity since it can only be attributed by members whom which a wallet is trading with.


## ⚠️ WARNING! ⚠️
This repo contains highly experimental code. Expect rapid iteration. Use at your own risk.

 
# Architecture
The protocol is based on three infrastructure Smart Contracts:
- **DAO**: Custom ERC20 contract that represents the ownership of the DAO. This contract is also the treasury to which all Asset Init / Minting fees go to.
- **txAsset**: Custom ERC721 contract that stores the terms of an asset as a minted NFT. This contract also contains the functionality that allows the buyer to agree to the asset and the NFT is also the received of the programmed payment stream. Furthermore, the NFT enables composability of sub NFTs.
- **txDharma**: Custom ERC20 contract that is non-transferable and mintable. Community members that are in an active asset are able to mint these tokens to their counerpart's wallets or burn them when attributing a negative score.

and a set of ERC20 wrapper contracts that enable all custom streaming and escrow functionality:
- **txFlow**: Custom ERC20 contract that wraps around the target token, eg. USDC, and contains the streaming and self-custody functionality. This contract is also extended to attribute a balance to any ERC721 contract.
- **txEscrow**: Custom ERC1155 contract that wraps around the locked escrow amount that flows towards the target in the Flow token above.


# Commercial Workflow
When starting on a commercial journey, both buyers and sellers engage through the Smart Contract infrastructure in an on-chain dynamic.
## Minting an Asset
The first steps are creating a new asset:

1. First both Buyer and Seller deposit ERC20 token (USDC) to the Flow tokens in order to make payments. The Seller pays minting fees and the Buyer pays the commercial fees in flow token.
2. Seller approves a transfer for each Flow token the asset is linked to for the Asset contract to charge the respective fees.
3. Seller mints a Asset NFT (_txAsset.init_) returning a tokenID.
4. Seller communicates the tokenID to the Buyer.
5. Buyer agrees to the asset (_txAsset.agree_) given the tokenID.
6. Buyer and Seller can now start to rate each other (_txAsset.rate_) given the tokenId.
7. Buyer starts adding programmed Flow token cashflows to the asset (_txFlow.addNFTMaturityStream_) given the tokenId.
8. Service provider is now able to withdraw Flow tokens from the NFT Asset (_txFlow.withdrawAmountNFT_) that are streamed to them as time passes.
9. Both Service providers and Buyers are able to withdraw Flow tokens (_txFlow.withdrawBase_) for the base token (USDC).

# Contracts
During this alpha phase, we are deploying a set of test contracts to the Goerli Starknet testnet. The production contract will be deployed at a later date on to mainnet.

## ⚠️ WARNING! ⚠️
All of the contract addresses below will change as we iterate rapidly during these initial phases. Please keep a look out for changes in these addresses.

## Infrastructure Alpha on Goerli Testnet
Deployment Date: 2022-07-18
| Contract |  Address |
:-------------------------:|:-------------------------: 
DAO      | [0x051cc37fae579cc5e8d92b451367b3e3a9d135c38bdda1fac01e5ffc8bcc34f5](https://goerli.voyager.online/contract/0x051cc37fae579cc5e8d92b451367b3e3a9d135c38bdda1fac01e5ffc8bcc34f5)
txAsset  | [0x05b9c2f5c0b79807cc75efceafb5052161421f8f7d3dc2889edf8d22775cf698](https://goerli.voyager.online/contract/0x05b9c2f5c0b79807cc75efceafb5052161421f8f7d3dc2889edf8d22775cf698)
txDharma | [0x03ad4a2587a8cd9c8bf292a580c7f134cbef216ea2b6582b9ebdc75c2837d8c2](https://goerli.voyager.online/contract/0x03ad4a2587a8cd9c8bf292a580c7f134cbef216ea2b6582b9ebdc75c2837d8c2)

## Flows Alpha on Goerli Testnet
Deployment Date: 2022-07-18
| Contract |  Address |
:-------------------------:|:-------------------------: 
ERC20 Test       | [0x032683e2234543d8edccc633bf7a6a0cf36d7f62858323f76018c90c455ea129](https://goerli.voyager.online/contract/0x032683e2234543d8edccc633bf7a6a0cf36d7f62858323f76018c90c455ea129)
ERC20 Test xFlow | [0x00f5b784c8dfc813cc881ccbe12ffc96135b423f38725691d5bc72524933bf1b](https://goerli.voyager.online/contract/0x00f5b784c8dfc813cc881ccbe12ffc96135b423f38725691d5bc72524933bf1b)
ERC1155 xFlow    | [0x032683e2234543d8edccc633bf7a6a0cf36d7f62858323f76018c90c455ea129](https://goerli.voyager.online/contract/0x032683e2234543d8edccc633bf7a6a0cf36d7f62858323f76018c90c455ea129)


# Environment
The development environment is based on [Hardhat](https://hardhat.org/) and the [ShardLabs Starknet plugin](https://github.com/Shard-Labs/starknet-hardhat-plugin). To work with this project you must first clone this repo. 

## Install
Make sure you have [npm](https://www.npmjs.com) and [docker](https://www.docker.com/) installed. Then in this project's root folder run

    npm install

## Compile

Compile all the contracts

    npx hardhat run scripts/compile-contracts.ts

    NB: at initial compilation, please set `paths: ["contracts"]` and then set it back to `paths: ["contracts/tradeflows"]`

## Local vs Chain
The development environment is set through the [hardhat.config.ts](./hardhat.config.ts) file through the **network** property:

    network: "devnet", // for localhost or
    network: "alpha" // for testnet 

If devnet is chosen, ie. localhost, then the [shardlabs](https://github.com/Shard-Labs/starknet-devnet) docker container must be running:

    docker run -it -p 127.0.0.1:5050:5050 shardlabs/starknet-devnet:0.2.3

    For apple silicon:
    docker run -it -p 127.0.0.1:5050:5050 shardlabs/starknet-devnet:0.2.3-arm

NOTE: The shardlabs/starknet-devnet image version 0.2.4 and 0.2.5 does not work. 

Upon start, the devnet will print out a list of wallet address and private keys with ETH. Use these in the **constants.ts** file as specified below.

# Scripts

To execute functions in Goerli Testnet you will need ETH which you can get through a faucet:
[StarkNet Faucet](https://faucet.goerli.starknet.io)

## Deploy
The smart contracts are divided into two categories. Infrastructure contracts that manage the **DAO**, **Asset** and **Rating** functionality; and the **Flow** wrapper contracts.

### Deploy Infrastructure

Instructure, ie. Asset and Dharma, contract deployment:

    npx hardhat run scripts/deploy-infrastructure.ts

### Deploy Wrapped Tokens

Wrapper token deployment. Please adapt the scripts for any new token to be deployed:

    npx hardhat run scripts/deploy-token.ts

## Operations
We have added an array of scripts to interact with the alpha infrastructure:

### Deposit ERC20 to ERC20 Flow
Script that deposits ERC20 tokens in the Flow contract to mint wrapper tokens. Note: this script requires the Owners private keys so this will not work in Testnet for the contracts in this document, you will need to deploy this to devnet.

    npx hardhat run scripts/deposit-base.ts

### ERC20 Balances
Script that checks the balance of the ERC20 test token

    npx hardhat run scripts/balance-erc20-check.ts


### ERC20 Flow Balances
Script that checks the balance of the ERC20 Flow test token

    npx hardhat run scripts/balance-flow-check.ts


# Testing

Create a copy of scripts/constants-example.ts and name it :

    scripts/constants.ts

Populate file accordingly, they will depend on the environment being devnet or alpha.

    export const walletAddressOwner         = '0x5d1120755d9d5380201a8ac8bf39f7c4e2dd886a5b1431b7ea8dfb4ea3f0624'
    export const walletPrivateOwner         = '0xfa9ccf36421a514a2b8bcd75e06b884b'

    export const walletAddress0             = '0x7b85aa6f0bcb77bc76efafd22dfbb36055bd4915fd77d7d357fd7d3b366d9da'
    export const walletPrivate0             = '0x3f195a2cc7e18acfea7b737abbac88f2'

    export const walletAddress1             = '0x10b0a921fe94090bba9d65478edb9a2fe17857bf719574a58b39cbe22d92e7c'
    export const walletPrivate1             = '0xebd2156a6161176df1dc826d487b58c1'



### Initial Workflow
Start by running scripts that deploy the entire infrastructure and test ERC20 tokens followed an execution of all relevant operations.

    npx hardhat test test/start.ts

Once you run this script, a set of address will be generated, copy these addresses to the 

    scripts/constants.ts

file. Example:

    export const daoContractAddress         = '0x03e122ff021fd9bf8952e55746ad095b751528ffcd5d40a4acc379a1d4431c25'
    export const erc20ContractAddress       = '0x02d704491ed20caa95afa45184b7e9c5ecf13e1a079fdbb5b95ea39ca592cf29'
    export const txFlowContractAddress      = '0x0746fffd49369c4bd3f5c970ff9885e0d4d3e6b6c43f2a15efea034dc61735a0'
    export const txDharmaContractAddress    = '0x030260d11b2cd88a410572b3011357857c9fcef9bd431d38c8dc0c47c7fdc835'
    export const txAssetContractAddress     = '0x05df41f469bf98be75e479385eee571ebedb72f70178fe00f17040f872c0b398'

### Run again
Then run the next test to ensure that recreating assets and rerunning these operations still works.

    npx hardhat test test/again.ts

# Notes
## ⚠️ WARNING! ⚠️
This repo contains highly experimental code. Expect rapid iteration. Use at your own risk.

## Collaboration
We are actively looking for contributors so please reach out if you are interested.

