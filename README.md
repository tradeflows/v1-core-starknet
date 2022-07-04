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
- Describe a trade's conditions and payment terms;
- Mint an NFT that represents the trade;
- Allows the buyer to agree to the trade on-chain through custom NFT functionality;
- The buyer can then link payment streams to the NFT;
- Collateralise the payment streams in order to show an availability of funds without losing control over them. The seller knows that as long as the funds are in the self-custody contract, they will only be used to pay the stream;
- Rate each other while there is a trade alive through a non-transferable ERC20 token. This offers a high social rating with a degree of integrity since it can only be attributed by members whom which a wallet is trading with.

Usage
⚠️ WARNING! ⚠️
This repo contains highly experimental code. Expect rapid iteration. Use at your own risk.

 
# Architecture
The protocol is based on three infrastructure Smart Contracts:
- **DAO**: Custom ERC20 contract that represents the ownership of the DAO. This contract is also the treasury to which all Trade Init / Minting fees go to.
- **txTrade**: Custom ERC721 contract that stores the terms of the trade as a minted NFT. This contract also contains the functionality that allows the buyer to agree to the trade and the NFT is also the received of the programmed payment stream.
- **txDharma**: Custom ERC20 contract that is non-transferable and mintable. Community members that are in an active trade are able to mint these tokens to their counerpart's wallets or burn them when attributing a negative score.

and a set of ERC20 wrapper contracts that enable all custom streaming and escrow functionality:
- **txFlow**: Custom ERC20 contract that wraps around the target token, eg. USDC, and contains the streaming and self-custody functionality. This contract is also extended to attribute a balance to any ERC721 contract.


# Commercial Workflow
When starting on a commercial journey, both buyers and sellers engage through the Smart Contract infrastructure in an on-chain dynamic.
## Minting a Trade
The first steps are creating a new trade:

1. First both Buyer and Seller deposit ERC20 token (USDC) to the Flow tokens in order to make payments. The Seller pays minting fees and the Buyer pays the commercial fees in flow token.
2. Seller approves a transfer for each Flow token the trade is linked to for the Trade contract to charge the respective fees.
3. Seller mints a Trade NFT (_txTrade.init_) returning a tokenID.
4. Seller communicates the tokenID to the Buyer.
5. Buyer agrees to the trade (_txTrade.agree_) given the tokenID.
6. Buyer and Seller can now start to rate each other (_txTrade.rate_) given the tokenId.
7. Buyer starts adding programmed Flow token cashflows to the trade (_txFlow.addNFTMaturityStream_) given the tokenId.
8. Service provider is now able to withdraw Flow tokens from the NFT Trade (_txFlow.withdrawAmountNFT_) that are streamed to them as time passes.
9. Both Service providers and Buyers are able to withdraw trade Flow tokens (_txFlow.withdrawBase_) for the base token (USDC).

# Contracts
During this alpha phase, we are deploying a set of test contracts to the Goerli Starknet testnet. The production contract will be deployed at a later date on to mainnet.

⚠️ WARNING! ⚠️
All of the contract addresses below will change as we iterate rapidly during these initial phases. Please keep a look out for changes in these addresses.

## Infrastructure Alpha on Goerli Testnet
| Contract |  Address |
:-------------------------:|:-------------------------: 
DAO      | [0x0351172e2bb614d3354c8c5aba22d777f6faeba2b66744f7116e96b79358dac0](https://goerli.voyager.online/contract/0x0351172e2bb614d3354c8c5aba22d777f6faeba2b66744f7116e96b79358dac0)
txTrade  | [0x04f7ce277a2d81fb20466f07017037e1a9762c308cc86a95f9534c61f3412714](https://goerli.voyager.online/contract/0x04f7ce277a2d81fb20466f07017037e1a9762c308cc86a95f9534c61f3412714)
txDharma | [0x07d00d72858504a84a1a09a06e60800811c2b8d720474ca420f2fa7bc1b1104a](https://goerli.voyager.online/contract/0x07d00d72858504a84a1a09a06e60800811c2b8d720474ca420f2fa7bc1b1104a)

## Flows Alpha on Goerli Testnet
| Contract |  Address |
:-------------------------:|:-------------------------: 
ERC20 Test       | [0x039bded9481f5fc7d46185c44655206362a647bb046dd97efcd2524a10bf7ab2](https://goerli.voyager.online/contract/0x039bded9481f5fc7d46185c44655206362a647bb046dd97efcd2524a10bf7ab2)
ERC20 Test xFlow | [0x002a63a6069e8209ad6bcab1d11d75cead44003aaaccbfad069954e32e533f35](https://goerli.voyager.online/contract/0x002a63a6069e8209ad6bcab1d11d75cead44003aaaccbfad069954e32e533f35)


# Environment
The development environment is based on [Hardhat](https://hardhat.org/) and the [ShardLabs Starknet plugin](https://github.com/Shard-Labs/starknet-hardhat-plugin). To work with this project you must first clone this repo. 

## Install
Make sure you have [npm](https://www.npmjs.com) and [docker](https://www.docker.com/) installed. Then in this project's root folder run

    npm install

## Compile

Compile all the contracts

    npx hardhat run scripts/compile-contracts.ts

## Local vs Chain
The development environment is set through the [hardhat.config.ts](./hardhat.config.ts) file through the **network** property:

    network: "devnet", // for localhost or
    network: "alpha" // for testnet 

If devnet is chosen, ie. localhost, then the [shardlabs](https://github.com/Shard-Labs/starknet-devnet) docker container must be running:

    docker run -it -p 127.0.0.1:5050:5050 shardlabs/starknet-devnet

Upon start, the devnet will print out a list of wallet address and private keys with ETH. Use these in the **constants.ts** file as specified below.

# Scripts

To execute functions in Goerli Testnet you will need ETH which you can get through a faucet:
[StarNet Faucet](https://faucet.goerli.starknet.io)

## Deploy
The smart contracts are divided into two categories. Infrastructure contracts that manage the **DAO**, **Trade** and **Rating** functionality; and the **Flow** wrapper contracts.

### Deploy Infrastructure

Instructure, ie. Trade and Dharma, contract deployment:

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

Please ensure the correct accounts are being used in the

    scripts/constants.ts

file. They will depend on the environment being devnet or alpha.

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
    export const txTradeContractAddress     = '0x05df41f469bf98be75e479385eee571ebedb72f70178fe00f17040f872c0b398'

### Run again
Then run the next test to ensure that recreating trades and rerunning these operations still works.

    npx hardhat test test/again.ts

# Notes
⚠️ WARNING! ⚠️
This repo contains highly experimental code. Expect rapid iteration. Use at your own risk.

We are actively looking for contributors so please reach out if you are interested.

