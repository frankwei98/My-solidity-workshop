import { ethers, BigNumber } from "ethers";
// Load process.env from dotenv
require("dotenv").config();

// Importing related complied contract code
import MatatakiPeggedTokenFactory from "../build/MatatakiPeggedTokenFactory.json";
import { BinanceSmartChain } from "./networks";

// Use the Rinkeby testnet
const network = BinanceSmartChain.TESTNET;
// Specify your own API keys
// Each is optional, and if you omit it the default
// API key for that service will be used.
const provider = new ethers.providers.JsonRpcProvider(network.rpcUrl, {
  name: "BSC Testnet",
  chainId: network.chainId,
});

const wallet = new ethers.Wallet(String(process.env.privateKey), provider);

async function main() {
  const blackList = "0x0a66824356baD4C02b2cbbe883779eEDD23348d3";
  const factory = await ethers.ContractFactory.fromSolidity(
    MatatakiPeggedTokenFactory,
    wallet
  ).deploy(blackList);
  const deployReceipt = await factory.deployTransaction.wait(1);
  console.info(`Factory deployed at: ${deployReceipt.contractAddress}`);
  const deployed = await factory._deployed();
  const res = await deployed.newAPeggedToken("FFFWWWCCC", "FWWWWC", 4);
  console.log(res)
}

main();
