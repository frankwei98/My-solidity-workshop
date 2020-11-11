import { expect, use } from "chai";
import { Contract } from "ethers";
import { deployContract, MockProvider, solidity } from "ethereum-waffle";
import BlacklistManager from "../build/BlacklistManager.json";
import Token from "../build/MatatakiPeggedToken.json";
import Factory from "../build/MatatakiPeggedTokenFactory.json";

use(solidity);

describe("PegTokenFactory", () => {
  const provider = new MockProvider({
    ganacheOptions: {
      hardfork: "istanbul",
      mnemonic: "horn horn horn horn horn horn horn horn horn horn horn horn",
      gasLimit: 9999999,
    },
  });
  const [wallet, walletTo] = provider.getWallets();
  let factory: Contract;
  let blacklistMgr: Contract;

  async function loadFixture() {
    const blacklistMgr = await deployContract(wallet, BlacklistManager, []);
    const factory = await deployContract(wallet, Factory, []);
    await factory.initBlacklistManager(blacklistMgr.address);
    expect(await factory.blacklistManager()).to.equal(blacklistMgr.address);
    return { blacklistMgr, factory, wallet };
  }

  beforeEach(async () => {
    const fixture = await loadFixture();
    blacklistMgr = fixture.blacklistMgr;
    factory = fixture.factory;
  });

  it("Revert 'initBlacklistManager' after BlacklistManager existed", async () => {
    await expect(factory.initBlacklistManager(blacklistMgr.address)).to.be
      .reverted;
  });

  it("Good to compute token address for DAO", async () => {
    const address = await factory.computeAddress("岛岛币", "DAO");
    console.info(
      `Computed Token address for DAO is: ${address}, based on factory address: ${factory.address}`
    );
    expect(address).to.not.equal("0x0000000000000000000000000000000000000000");
  });

  it("New Pegged Token will emits event", async () => {
    const [name, symbol] = ["岛岛币", "DAO"];
    const computedTokenAddress = await factory.computeAddress(name, symbol);

    await expect(factory.newAPeggedToken(name, symbol, 4)).to.emit(
      factory,
      "NewPeggedToken"
    );
    expect(await factory.allPeggedTokens(0)).to.equal(computedTokenAddress);
  });
  // it("Deposit USDT into unitedMint", async () => {
  //   await fakeYDeposit.usdtTap(1000000);
  //   await usdt.approve(unitedMint.address, 1000000);
  //   await unitedMint.deposit(1000000);
  //   expect(await unitedMint.balanceOf(wallet.address)).to.equal(1000000);
  // });

  // it("Deposit emits event", async () => {
  //   const amount = 1145141919810;
  //   await fakeYDeposit.usdtTap(amount);
  //   await usdt.approve(unitedMint.address, amount);
  //   await expect(unitedMint.deposit(amount))
  //     .to.emit(unitedMint, "Deposit")
  //     .withArgs(wallet.address, amount);
  // });

  // it("Can not Deposit if not approved", async () => {
  //   const soBig = "0xFFFFFFFFFFFFFFFFFFFFFFFFFFF";
  //   await expect(unitedMint.deposit(soBig)).to.be.reverted;
  // });

  // it("Can convert from usdt to yyCrv", async () => {
  //   const amount = 1000000;
  //   const minCrvWillGet = Math.floor(amount * 0.9);
  //   await fakeYDeposit.usdtTap(amount);
  //   await usdt.approve(unitedMint.address, amount);
  //   await unitedMint.deposit(amount);
  //   await unitedMint.mint();
  //   await unitedMint.claim();
  //   expect(await yyCrv.balanceOf(wallet.address)).to.gt(minCrvWillGet);
  // });

  // it("Calls balanceOf with sender address on unitedMint contract", async () => {
  //   await unitedMint.balanceOf(wallet.address);
  //   expect("balanceOf").to.be.calledOnContractWith(unitedMint, [
  //     wallet.address,
  //   ]);
  // });
});
