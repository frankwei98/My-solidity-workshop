import { expect, use } from "chai";
import { Contract, ethers } from "ethers";
import { deployContract, MockProvider, solidity } from "ethereum-waffle";
import BlacklistManager from "../build/BlacklistManager.json";
import Token from "../build/MatatakiPeggedToken.json";
import Factory from "../build/MatatakiPeggedTokenFactory.json";

use(solidity);

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

describe("PegTokenFactory", () => {
  const provider = new MockProvider({
    ganacheOptions: {
      hardfork: "istanbul",
      mnemonic: "horn horn horn horn horn horn horn horn horn horn horn horn",
      gasLimit: 9999999,
    },
  });
  const [
    managerWallet,
    designateBadDude,
    someRandomAss,
  ] = provider.getWallets();
  let factory: Contract;
  let blacklistMgr: Contract;

  async function loadFixture() {
    const blacklistMgr = await deployContract(
      managerWallet,
      BlacklistManager,
      []
    );
    
    const factory = await deployContract(managerWallet, Factory, []);
    await factory.initBlacklistManager(blacklistMgr.address);
    expect(await factory.blacklistManager()).to.equal(blacklistMgr.address);
    return { blacklistMgr, factory, wallet: managerWallet };
  }

  beforeEach(async () => {
    const fixture = await loadFixture();
    blacklistMgr = fixture.blacklistMgr;
    factory = fixture.factory;
  });

  it("Revert if 'initBlacklistManager' was triggered before", async () => {
    await expect(factory.initBlacklistManager(blacklistMgr.address)).to.be
      .reverted;
  });

  it("Able to compute the token address based on name and symbol", async () => {
    const address = await factory.computeAddress("岛岛币", "DAO");
    console.info(
      `Computed Token address for 岛岛币 is: ${address}, based on factory address: ${factory.address}`
    );
    expect(address).to.not.equal(ZERO_ADDRESS);
  });

  it("Good to Produce New Pegged Token", async () => {
    const [name, symbol] = ["岛岛币", "DAO"];
    const computedTokenAddress = await factory.computeAddress(name, symbol);

    await expect(factory.newAPeggedToken(name, symbol, 4)).to.emit(
      factory,
      "NewPeggedToken"
    );
    expect(await factory.allPeggedTokens(0)).to.equal(computedTokenAddress);
  });

  it("Transfer token to someone", async () => {
    const [name, symbol] = ["USD Trump", "USDT"];
    const computedTokenAddress = await factory.computeAddress(name, symbol);

    await expect(factory.newAPeggedToken(name, symbol, 4)).to.emit(
      factory,
      "NewPeggedToken"
    );
    const usdtWithAdmin = new Contract(
      computedTokenAddress,
      Token.abi,
      provider
    ).connect(managerWallet);
    const amount = "19198100000";
    await usdtWithAdmin.mint(managerWallet.address, amount);
    // Transfer
    await expect(usdtWithAdmin.transfer(someRandomAss.address, amount))
      .to.emit(usdtWithAdmin, "Transfer")
      .withArgs(managerWallet.address, someRandomAss.address, amount);
  });

  it("Can Mint and Burn token as admin", async () => {
    const [name, symbol] = ["小富币", "FWC"];
    const computedTokenAddress = await factory.computeAddress(name, symbol);

    await expect(factory.newAPeggedToken(name, symbol, 4)).to.emit(
      factory,
      "NewPeggedToken"
    );
    const fwcToken = new Contract(
      computedTokenAddress,
      Token.abi,
      provider
    ).connect(managerWallet);
    const amount = "1145141919810";
    // Mint
    await expect(fwcToken.mint(someRandomAss.address, amount))
      .to.emit(fwcToken, "Transfer")
      .withArgs(ZERO_ADDRESS, someRandomAss.address, amount);
    // And BURN that Ass
    await expect(fwcToken.burn(someRandomAss.address, amount))
      .to.emit(fwcToken, "Transfer")
      .withArgs(someRandomAss.address, ZERO_ADDRESS, amount);
  });

  it("Ban someone from transfer token out", async () => {
    const [name, symbol] = ["USD Trump", "USDT"];
    const computedTokenAddress = await factory.computeAddress(name, symbol);

    await expect(factory.newAPeggedToken(name, symbol, 4)).to.emit(
      factory,
      "NewPeggedToken"
    );
    const usdtWithAdmin = new Contract(
      computedTokenAddress,
      Token.abi,
      provider
    ).connect(managerWallet);
    const usdtWithBadDude = usdtWithAdmin.connect(designateBadDude);
    const amount = "19198100000";

    // Let's say he hacked something, and got a lot of money
    // Print money to his account just for example
    await expect(usdtWithAdmin.mint(designateBadDude.address, amount))
      .to.emit(usdtWithAdmin, "Transfer")
      .withArgs(ZERO_ADDRESS, designateBadDude.address, amount);

    // Let's say the random dude got money for bad dude
    await expect(usdtWithAdmin.mint(someRandomAss.address, amount))
      .to.emit(usdtWithAdmin, "Transfer")
      .withArgs(ZERO_ADDRESS, someRandomAss.address, amount);

    // We come in and ban his ass
    await expect(
      blacklistMgr.enlistPeoples([designateBadDude.address])
    ).to.emit(blacklistMgr, "Enlist");

    // And Bad dude can not do anything, boo
    await expect(
      usdtWithBadDude.transfer(someRandomAss.address, amount)
    ).to.be.revertedWith(
      "MatatakiPeggedToken::FROM_IN_BLACKLIST: The from wallet was banned. Please contact Matataki Team ASAP."
    );
  });

  it("Ban someone from receive any token", async () => {
    const [name, symbol] = ["USD Trump", "USDT"];
    const computedTokenAddress = await factory.computeAddress(name, symbol);

    await expect(factory.newAPeggedToken(name, symbol, 4)).to.emit(
      factory,
      "NewPeggedToken"
    );
    const usdtWithAdmin = new Contract(
      computedTokenAddress,
      Token.abi,
      provider
    ).connect(managerWallet);
    const usdtWithRandomDude = usdtWithAdmin.connect(someRandomAss);
    const amount = "19198100000";

    // Let's say the random dude got money for bad dude
    await expect(usdtWithAdmin.mint(someRandomAss.address, amount))
      .to.emit(usdtWithAdmin, "Transfer")
      .withArgs(ZERO_ADDRESS, someRandomAss.address, amount);

    // We come in and ban his ass
    await expect(
      blacklistMgr.enlistPeoples([designateBadDude.address])
    ).to.emit(blacklistMgr, "Enlist");

    // Not even getting money in
    await expect(
      usdtWithRandomDude.transfer(designateBadDude.address, amount)
    ).to.be.revertedWith(
      "MatatakiPeggedToken::TO_IN_BLACKLIST: The to wallet was banned. Please contact Matataki Team ASAP."
    );
  });
});
