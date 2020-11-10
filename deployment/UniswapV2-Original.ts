import { ethers, BigNumber } from "ethers";
// Load process.env from dotenv
require("dotenv").config();


// Importing related complied contract code
// import UniswapV2Factory from "../uniswap-build/UniswapV2Factory.json";
// import UniswapV2Router01 from "../uniswap-build/UniswapV2Router01.json";
// import UniswapV2Router02 from "../uniswap-build/UniswapV2Router02.json";
import UniswapV2Router02 from "../build/UniswapV2Router02.json";

// Use the Rinkeby testnet
const network = "rinkeby";
// Specify your own API keys
// Each is optional, and if you omit it the default
// API key for that service will be used.
const provider = ethers.getDefaultProvider(network, {
  infura: process.env.InfuraId,
});

const wallet = new ethers.Wallet(String(process.env.privateKey), provider);

async function main() {
    // const factory = await ethers.ContractFactory.fromSolidity(UniswapV2Factory, wallet).deploy(
    //     "0x9dd18754F77d39B8640C436e8a9Ea4cAca411E96"
    // )
    const wethAddress = '0xc778417E063141139Fce010982780140Aa0cD5Ab';
    // const factoryReceipt = await factory.deployTransaction.wait(1);
    // const factoryAddress = factoryReceipt.contractAddress;
    const factoryAddress = "0x71f8ce7abdd57aed9732a28970ad522b435c265a"
    console.log(`Factory: ${factoryAddress}`)
    // const router01 = await ethers.ContractFactory.fromSolidity(UniswapV2Router01, wallet).deploy(
    //     factoryAddress,
    //     wethAddress
    // );

    // const router01Receipt = await router01.deployTransaction.wait(1);
    // console.info(`Router01: ${router01Receipt.contractAddress}`)
    const router02 = await ethers.ContractFactory.fromSolidity(UniswapV2Router02, wallet).deploy(
        factoryAddress,
        wethAddress
    );
    const router02Receipt = await router02.deployTransaction.wait(1);
    console.info(`Router02: ${router02Receipt.contractAddress}`)
}


main();
