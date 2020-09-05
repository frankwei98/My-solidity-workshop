import { ethers } from "ethers";
// Load process.env from dotenv
require("dotenv").config();

// Importing related complied contract code
import FakeYDeposit from "../build/FakeYDeposit.json";
import UnitedMint from "../build/UnitedMint.json";
import TokenThatAnyoneCanMint from "../build/TokenThatAnyoneCanMint.json";
import FakeYYCrv from "../build/FakeYYCrv.json";

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
  const USDT = await TokenFactory.deploy("Fake USDT 0905", "FUSDT95", 6);
  const yCrv = await TokenFactory.deploy("Fake yCrv 0905", "FyCrv95", 18);

  await Promise.all([
    USDT.deployTransaction.wait(1),
    yCrv.deployTransaction.wait(1),
  ]);

  const yyCrv = await ethers.ContractFactory.fromSolidity(
    FakeYYCrv,
    wallet
  ).deploy(yCrv.address);

  await yyCrv.deployTransaction.wait(1);

  return [USDT.address, yCrv.address, yyCrv.address];
}

async function deployYDeposit(usdt: string, ycrv: string) {
  console.info("===== Deploying FakeYDeposit =====");
  const _yDepo = await ethers.ContractFactory.fromSolidity(
    FakeYDeposit,
    wallet
  ).deploy(usdt, ycrv);
  await _yDepo.deployTransaction.wait(1);
  console.info("===== yDeposit Deployed =====");
  const yDeposit = await _yDepo.deployed();
  console.log("yDeposit @ ", yDeposit.address);
  return yDeposit.address;
}

async function main() {
  //   const [usdt, ycrv, yyCrv] = await deployFakeTokens();
  const [usdt, ycrv, yyCrv] = [
    "0x6C3267A44BdAbeC81F291e1a8E7949D6b032cdE6",
    "0xDA12C4c3497Ba0704194D1eE9833b6ed8Cb9ED79",
    "0xf11d23732Ac6c1d749b9B39F6aBceE0e089F5796",
  ];
  // const [ usdt, ycrv ] = ['0x94F5ecd5309f51702E58812d411284E9354d69db', '0x64B9B14749d798715e898032CFd40d3Cc522e8D0'];
  //   const yDepositAddr = await deployYDeposit(usdt, ycrv);
  const yDepositAddr = "0xB7db2f602Ea790B21a5519fFCFc256D7618f2fc2";

  console.info("===== Deploying UnitedMint =====");
  const _uniDepo = await ethers.ContractFactory.fromSolidity(
    UnitedMint,
    wallet
  ).deploy(usdt, ycrv, yDepositAddr, yyCrv);
  const receipt = await _uniDepo.deployTransaction.wait(1);
  console.info("===== UnitedMint Deployed =====");
  const unitedMint = await _uniDepo.deployed();
  // 0xA5a857eBdF704dfA98623428CA426AcEf9d08cB9
  console.log("UnitedMint @ ", unitedMint.address);
}

main();
