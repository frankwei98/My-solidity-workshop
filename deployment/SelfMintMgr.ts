import { ethers, utils } from "ethers";
// Load process.env from dotenv
require("dotenv").config();

// Importing related complied contract code
import PeggedTokenMinter from "../build/PeggedTokenMinter.json";
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

async function deploy() {
  const blackList = "0xBD98FB43Ea8Cfc94D4fd0Fe61BcE98B64579dc55";
  const factory = await ethers.ContractFactory.fromSolidity(
    PeggedTokenMinter,
    wallet
  ).deploy(blackList);
  const deployReceipt = await factory.deployTransaction.wait(1);
  console.info(`Factory deployed at: ${deployReceipt.contractAddress}`);
  // const deployed = await factory._deployed();
  // await deployed.initBlacklistManager(blackList);
  // console.info("initized BlacklistManager");
  // const res = await deployed.newAPeggedToken("FFFWWWCCC", "FWWWWC", 4);
  // console.log(res)
}

interface Signature {
  r: string;
  s: string;
  v: number;
}

async function signPermit(
  token: string,
  to: string,
  nonce: number,
  value: string,
  // In Minutes
  validFor: number
) {
  const domain = {
    name: 'PeggedTokenMinter',
    version: '1',
    chainId: 0x61,
    verifyingContract: '0xe8142C86f7c25A8bF1c73Ab2A5Dd7a7A5C429171'
  };

  // The named list of all type definitions
  const types = {
    "Permit": [{
      "name": "token",
      "type": "address"
      },
      {
        "name": "to",
        "type": "address"
      },
      {
        "name": "value",
        "type": "uint256"
      },
      {
        "name": "nonce",
        "type": "uint256"
      },
      {
        "name": "deadline",
        "type": "uint256"
      }
    ]
  }
  const deadline = Math.floor(((new Date().getTime() + (validFor * 1000 * 60)) / 1000))
  // The data to sign
  const msg = {
    token,
    to,
    value,
    nonce,
    deadline
  };
  const sig = await wallet._signTypedData(domain, types, msg);
  return { sig: utils.splitSignature(sig), ...msg }
}

// deploy();
signPermit(
  '0x9b64a89da98d660c58a34f49b993a28fe7265f3e',
  '0x2F129a52aAbDcb9Fa025BFfF3D4C731c2D914932',
  1, "1145141919",
  30).then(sig => console.info('sig: ', sig))