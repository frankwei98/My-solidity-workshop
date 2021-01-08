import { ethers } from "ethers";
import { readFileSync } from "fs";

let httpProvider = new ethers.providers.JsonRpcProvider(
  "https://bsc-dataseed.binance.org/"
);

console.log("Sending...");

const fileLocation = process.argv[2];

const content = readFileSync(fileLocation, { encoding: "utf-8" });

const fileAsObject = JSON.parse(content);

if (fileAsObject.transaction) {
  httpProvider.sendTransaction(fileAsObject.transaction).then((result) => {
    console.log(result);
  });
}
