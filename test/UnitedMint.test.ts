import { expect, use } from "chai";
import { Contract } from "ethers";
import { deployContract, MockProvider, solidity } from "ethereum-waffle";
import FakeYDeposit from "../build/FakeYDeposit.json";
import UnitedMint from "../build/UnitedMint.json";
import FakeYYCrv from "../build/FakeYYCrv.json";
import TokenThatAnyoneCanMint from "../build/TokenThatAnyoneCanMint.json";

use(solidity);

describe("UnitedMint", () => {
  const [wallet, walletTo] = new MockProvider().getWallets();
  let fakeYDeposit: Contract;
  let unitedMint: Contract;
  let yCrv: Contract, usdt: Contract, yyCrv: Contract;

  beforeEach(async () => {
    usdt = await deployContract(wallet, TokenThatAnyoneCanMint, [
      "Fake USDT",
      "FUSDT",
      6,
    ]);
    yCrv = await deployContract(wallet, TokenThatAnyoneCanMint, [
      "Fake yCrv",
      "FyCrv",
      18,
    ]);
    yyCrv = await deployContract(wallet, FakeYYCrv, [yCrv.address]);
    fakeYDeposit = await deployContract(wallet, FakeYDeposit, [
      usdt.address,
      yCrv.address,
    ]);
    unitedMint = await deployContract(wallet, UnitedMint, [
      usdt.address,
      yCrv.address,
      fakeYDeposit.address,
      yyCrv.address
    ]);
  });

  it("Fake USDT watertap is working", async () => {
    await fakeYDeposit.usdtTap(1000000);
    expect(await usdt.balanceOf(wallet.address)).to.equal(1000000);
  });

  it("Deposit USDT into unitedMint", async () => {
    await fakeYDeposit.usdtTap(1000000);
    await usdt.approve(unitedMint.address, 1000000);
    await unitedMint.deposit(1000000);
    expect(await unitedMint.balanceOf(wallet.address)).to.equal(1000000);
  });

  it("Deposit emits event", async () => {
    const amount = 1145141919810;
    await fakeYDeposit.usdtTap(amount);
    await usdt.approve(unitedMint.address, amount);
    await expect(unitedMint.deposit(amount))
      .to.emit(unitedMint, "Deposit")
      .withArgs(wallet.address, amount);
  });

  it("Can not Deposit if not approved", async () => {
    const soBig = "0xFFFFFFFFFFFFFFFFFFFFFFFFFFF";
    await expect(unitedMint.deposit(soBig)).to.be.reverted;
  });

  it("Can convert from usdt to yyCrv", async () => {
    const amount = 1000000;
    const minCrvWillGet = Math.floor(amount * 0.9);
    await fakeYDeposit.usdtTap(amount);
    await usdt.approve(unitedMint.address, amount);
    await unitedMint.deposit(amount);
    await unitedMint.mint();
    await unitedMint.claim();
    expect(await yyCrv.balanceOf(wallet.address)).to.gt(minCrvWillGet);
  });

  it("Calls balanceOf with sender address on unitedMint contract", async () => {
    await unitedMint.balanceOf(wallet.address);
    expect("balanceOf").to.be.calledOnContractWith(unitedMint, [
      wallet.address,
    ]);
  });
});
