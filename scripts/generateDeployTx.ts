import { BigNumber, ContractFactory, ethers, utils, Wallet } from "ethers";
import { writeFileSync, readFileSync } from "fs";

const mainnet = new ethers.providers.JsonRpcProvider(
  "https://bsc-dataseed.binance.org/"
);

// Testnet
const testnet = new ethers.providers.JsonRpcProvider(
  "https://data-seed-prebsc-1-s1.binance.org:8545/"
);

const httpProvider = process.argv[2] === "mainnet" ? mainnet : testnet;
const contractBuildFile = JSON.parse(readFileSync(process.argv[3], 'utf-8'));

function signatureBuilder(
  repeatedHexWordForR: string,
  repeatedHexWordForS: string,
  vInDecimal: 27 | 28
): string {
  const r = Array(16).fill(repeatedHexWordForR).join("");
  const s = Array(16).fill(repeatedHexWordForS).join("");
  const v = vInDecimal === 27 ? "1b" : "1c";
  return `${v}a0${r}a0${s}`;
}

// @XXX: Heads up! this is some asshole's key(from 'here's my private key' scam)
// DO NOT USE your own keys. 
// We just need this to generate a transaction, that we can fxxk with its signature
const wallet = new Wallet(
  "0x1993e34e5e8b2ac42b40a55218bb2be15bef3009c33b4ddac9d84352f3bcb8ed"
);
const factory = new ContractFactory(
  contractBuildFile.abi,
  contractBuildFile.bytecode,
  wallet
);
const params: any[] = process.argv.slice(4);
console.info('contract constructor params: ', params)
let contractDeployTx = factory.getDeployTransaction(...params);
//
//ADAPTED FROM https://github.com/LimeChain/IdentityProxy/blob/master/relayer_api/services/relayerService.js
//
wallet
  .connect(httpProvider)
  .estimateGas(contractDeployTx)
  .then((apprxGasLimit) =>
    console.info("apprxGasLimit", apprxGasLimit.toString())
  );

contractDeployTx.gasLimit = BigNumber.from("698785");

contractDeployTx.gasPrice = utils.parseUnits("20", "gwei");
wallet.signTransaction(contractDeployTx).then((signedDeployTx) => {
  const signedTransNoRSV = signedDeployTx.substring(
    0,
    signedDeployTx.length - 134
  );
  const rsvDeterministicallyByHuman = signatureBuilder("beee", "1919", 27);
  console.info("rsv", rsvDeterministicallyByHuman);

  let counterfactualTx = `${signedTransNoRSV}${rsvDeterministicallyByHuman}`;
  const parsedTrans = utils.parseTransaction(counterfactualTx);
  console.info("tx:r", parsedTrans.r);
  console.info("tx:s", parsedTrans.s);
  console.info("tx:v", parsedTrans.v);

  const counterfactualDeploymentPayer = parsedTrans.from as string;
  httpProvider
    .getTransactionCount(counterfactualDeploymentPayer)
    .then((nonce) => {
      const transaction = {
        from: counterfactualDeploymentPayer,
        nonce: nonce,
      };
      const counterfactualContractAddress = utils.getContractAddress(
        transaction
      );
      let result = {
        transactionWithoutSig: signedTransNoRSV,
        transaction: counterfactualTx,
        from: counterfactualDeploymentPayer,
        gasPrice: contractDeployTx.gasPrice,
        gasLimit: contractDeployTx.gasLimit,
        address: counterfactualContractAddress,
        nonce: nonce,
      };

      writeFileSync(
        "./generated.deploy.json",
        JSON.stringify(result, null, 2)
      );
      const txFee = (result.gasPrice as BigNumber).mul(
        result.gasLimit as BigNumber
      );
      console.info(
        `Please fund ${utils.formatEther(
          txFee
        )} ETH/BNB to ${counterfactualDeploymentPayer} in order to deploy at gasPrice: ${utils.formatUnits(
          result.gasPrice as BigNumber,
          "gwei"
        )} gwei & gasLimit: ${result.gasLimit}`
      );
    });
});
