import { ethers } from "ethers";
// Load process.env from dotenv
require('dotenv').config();

// Importing related complied contract code
import FakeYDeposit from '../build/FakeYDeposit.json';
import UniDeposit from '../build/UniDeposit.json';
import TokenThatAnyoneCanMint from "../build/TokenThatAnyoneCanMint.json";
import { util } from "chai";

// Use the Rinkeby testnet
const network = "mainnet";
// Specify your own API keys
// Each is optional, and if you omit it the default
// API key for that service will be used.
const provider = ethers.getDefaultProvider(network, {
    infura: process.env.InfuraId,
});

const wallet = new ethers.Wallet(String(process.env.privateKey), provider);

// async function deployFakeTokens() {
//     const TokenFactory = new ethers.ContractFactory(
//         TokenThatAnyoneCanMint.abi, 
//         TokenThatAnyoneCanMint.bytecode, 
//         wallet
//     );
//     const USDT = await TokenFactory.deploy("Fake USDT", "FUSDT", 6);
//     const yCrv = await TokenFactory.deploy("Fake yCrv", "FyCrv", 18);

//     await Promise.all([
//         USDT.deployTransaction.wait(1),
//         yCrv.deployTransaction.wait(1)
//     ])

//     return [ USDT.address, yCrv.address ]
// }

async function main() {
    // const [ usdt, ycrv ] = await deployFakeTokens();
    const [ usdt, ycrv ] = ['0xdac17f958d2ee523a2206206994597c13d831ec7', '0xdf5e0e81dff6faf3a7e52ba697820c5e32d806a8'];
    const yDeposit = '0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3'
    const contract = ethers.ContractFactory.fromSolidity(UniDeposit, wallet);
    const request = contract.getDeployTransaction(usdt, ycrv, yDeposit)
    const gas = await provider.estimateGas(request);
    console.log('est. gas: ', gas.toString());
    // const _uniDepo = await contract.deploy(usdt, ycrv, yDeposit);
    // await _uniDepo.deployTransaction.wait(1);
    // console.info('===== uniDeposit Deployed =====')
    // const uniDeposit = await _uniDepo.deployed();
    // console.log('uniDeposit @ ', uniDeposit.address);
}

main();