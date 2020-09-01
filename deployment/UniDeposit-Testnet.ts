import { ethers } from "ethers";
// Load process.env from dotenv
require('dotenv').config();

// Importing related complied contract code
import FakeYDeposit from '../build/FakeYDeposit.json';
import UniDeposit from '../build/UniDeposit.json';
import TokenThatAnyoneCanMint from "../build/TokenThatAnyoneCanMint.json";

// Use the Rinkeby testnet
const network = "rinkeby";
// Specify your own API keys
// Each is optional, and if you omit it the default
// API key for that service will be used.
const provider = ethers.getDefaultProvider(network, {
    infura: process.env.InfuraId,
});

const wallet = new ethers.Wallet(String(process.env.privateKey), provider);

async function deployFakeTokens() {
    const TokenFactory = new ethers.ContractFactory(
        TokenThatAnyoneCanMint.abi, 
        TokenThatAnyoneCanMint.bytecode, 
        wallet
    );
    const USDT = await TokenFactory.deploy("Fake USDT", "FUSDT", 6);
    const yCrv = await TokenFactory.deploy("Fake yCrv", "FyCrv", 18);

    await Promise.all([
        USDT.deployTransaction.wait(1),
        yCrv.deployTransaction.wait(1)
    ])

    return [ USDT.address, yCrv.address ]
}

async function main() {
    // const [ usdt, ycrv ] = await deployFakeTokens();
    const [ usdt, ycrv ] = ['0x94F5ecd5309f51702E58812d411284E9354d69db', '0x64B9B14749d798715e898032CFd40d3Cc522e8D0'];
    console.info('===== Deploying FakeYDeposit =====')
    const _yDepo = await ethers.ContractFactory.fromSolidity(FakeYDeposit, wallet).deploy(usdt, ycrv);
    await _yDepo.deployTransaction.wait(1);
    console.info('===== yDeposit Deployed =====')
    const yDeposit = await _yDepo.deployed();
    console.log('yDeposit @ ', yDeposit.address);
    console.info('===== Deploying UniDeposit =====')
    const _uniDepo = await ethers.ContractFactory.fromSolidity(UniDeposit, wallet).deploy(usdt, ycrv, yDeposit.address);
    await _uniDepo.deployTransaction.wait(1);
    console.info('===== uniDeposit Deployed =====')
    const uniDeposit = await _uniDepo.deployed();
    console.log('uniDeposit @ ', uniDeposit.address);
}

main();