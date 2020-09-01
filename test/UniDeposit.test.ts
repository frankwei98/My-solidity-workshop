import {expect, use} from 'chai';
import {Contract} from 'ethers';
import {deployContract, MockProvider, solidity} from 'ethereum-waffle';
import {deployENS, ENS} from '@ethereum-waffle/ens';
import FakeYDeposit from '../build/FakeYDeposit.json';
import UniDeposit from '../build/UniDeposit.json';
import TokenThatAnyoneCanMint from "../build/TokenThatAnyoneCanMint.json";

use(solidity);

describe('UniDeposit', () => {
  const [wallet, walletTo] = new MockProvider().getWallets();
  let fakeYDeposit: Contract;
  let unideposit: Contract;
  let yCrv: Contract, usdt: Contract;

  beforeEach(async () => {
    usdt = await deployContract(wallet, TokenThatAnyoneCanMint, [
      "Fake USDT", "FUSDT", 6
    ]);
    yCrv = await deployContract(wallet, TokenThatAnyoneCanMint, [
      "Fake yCrv", "FyCrv", 18
    ]);
    fakeYDeposit = await deployContract(wallet, FakeYDeposit, [
      usdt.address, yCrv.address
    ]);    
    unideposit = await deployContract(wallet, UniDeposit, [
      usdt.address, yCrv.address, fakeYDeposit.address
    ]);
  });

  it('Fake USDT watertap is working', async () => {
    await fakeYDeposit.usdtTap(1000000);
    expect(await usdt.balanceOf(wallet.address)).to.equal(1000000);
  });

  it('Deposit USDT into UniDeposit', async () => {
    await fakeYDeposit.usdtTap(1000000);
    await usdt.approve(unideposit.address, 1000000);
    await unideposit.deposit(1000000);
    expect(await unideposit.balanceOf(wallet.address)).to.equal(1000000);
  });

  it('Deposit emits event', async () => {
    const amount = 1145141919810
    await fakeYDeposit.usdtTap(amount);
    await usdt.approve(unideposit.address, amount);
    await expect(unideposit.deposit(amount))
      .to.emit(unideposit, 'Deposit')
      .withArgs(wallet.address, amount);
  });

  it('Can not Deposit if not approved', async () => {
    const soBig = '0xFFFFFFFFFFFFFFFFFFFFFFFFFFF';
    await expect(unideposit.deposit(soBig)).to.be.reverted;
  });

  it('Can convert usdt to yCrv', async () => {
    const amount = 1000000;
    const minCrvWillGet = Math.floor(amount * 0.9);
    await fakeYDeposit.usdtTap(amount);
    await usdt.approve(unideposit.address, amount);
    await unideposit.deposit(amount);
    await unideposit.mint();
    await unideposit.withdraw();
    expect(await yCrv.balanceOf(wallet.address)).to.gt(minCrvWillGet);
  });

  it('Calls balanceOf with sender address on UniDeposit contract', async () => {
    await unideposit.balanceOf(wallet.address);
    expect('balanceOf').to.be.calledOnContractWith(unideposit, [wallet.address]);
  });
});