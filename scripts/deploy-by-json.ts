import { ethers, utils } from "ethers";
import { parseTransaction } from "ethers/lib/utils";
import { readFileSync } from "fs";

const mainnet = new ethers.providers.JsonRpcProvider(
  "https://bsc-dataseed.binance.org/"
);

// Testnet
const testnet = new ethers.providers.JsonRpcProvider(
  "https://data-seed-prebsc-1-s1.binance.org:8545/"
);

const httpProvider = process.argv[3] === "mainnet" ? mainnet : testnet;

console.log("Sending...");

const fileLocation = process.argv[2];

const content = readFileSync(fileLocation, { encoding: "utf-8" });

const fileAsObject = JSON.parse(content);

const parsedTx = utils.parseTransaction(fileAsObject.transaction);
console.info("parsedTx", parsedTx);

if (fileAsObject.transaction) {
  httpProvider.sendTransaction(fileAsObject.transaction).then(async (result) => {
    console.info('Tx Send, txhash:', result.hash);
    const receipt = await result.wait();
    console.info('Tx receipt:', receipt);
  });
}
