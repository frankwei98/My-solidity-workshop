import { ethers, BigNumber } from "ethers";
// Load process.env from dotenv
require("dotenv").config();

// Importing related complied contract code
import MatatakiPeggedTokenFactory from "../build/MatatakiPeggedTokenFactory.json";

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
  const router02 = await ethers.ContractFactory.fromSolidity(
    MatatakiPeggedTokenFactory,
    wallet
  ).deploy();
  const router02Receipt = await router02.deployTransaction.wait(1);
  console.info(`Router02: ${router02Receipt.contractAddress}`);
}

main();
