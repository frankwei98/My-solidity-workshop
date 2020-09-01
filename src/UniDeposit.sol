// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;
// only use ABIEncoderV2 to return rich data, no worry
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IyDeposit.sol";
import "./IUSDT.sol";

/**
 * UniMint - Deposit USDT and Mint yCRV together
 */

contract UniDeposit {
    using SafeMath for uint256;
    address public USDT;
    address public yCrvToken;

    mapping(address=>uint256) _balance; // 每个用户的 USDT 数。

    function setBalance(address who, uint256 amount) internal {
        _balance[who] = amount;
    }
    function balanceOf(address who) public view returns (uint256) {
        return _balance[who];
    }

    uint256 public mintedUSDT; // USDT involved in minting yCRV
    uint256 public unmintedUSDT; // USDT not involved yet in minting yCRV
    uint256 public minted_yCRV; // yCRV minted for now, can cal the price with mintedUSDT

    address public yDeposit;

    constructor(address _usdt, address _ycrv, address _depositContract) public {
        USDT = _usdt;
        yCrvToken = _ycrv;
        yDeposit = _depositContract;
    }

    string constant INSUFFICIENT_BALANCE = "You don't have that much balance for us";
    string constant INSUFFICIENT_ALLOWANCE = "Insufficient Allowance. Please Approve again.";

    modifier goodToChargeToken(IERC20 token, uint256 amount) {
        require(token.balanceOf(msg.sender) >= amount, INSUFFICIENT_BALANCE);
        require(token.allowance(msg.sender, address(this)) >= amount, INSUFFICIENT_ALLOWANCE);
        _;
    }

    modifier goodToChargeUSDT(uint256 amount) {
        require(IUSDT(USDT).balanceOf(msg.sender) >= amount, INSUFFICIENT_BALANCE);
        require(IUSDT(USDT).allowance(msg.sender, address(this)) >= amount, INSUFFICIENT_ALLOWANCE);
        _;
    }

    function get_yCrvFromUsdt(uint256 amount) public view returns (uint256) {
        return amount.mul(minted_yCRV).div(mintedUSDT);
    }


    function deposit(uint256 amount) public goodToChargeUSDT(amount) {
        // sadly no return from USDT
        IUSDT(USDT).transferFrom(msg.sender, address(this), amount);
        if (amount > mintedUSDT) {
            // New Deposit goes to unmintedUSDT pool
            unmintedUSDT = unmintedUSDT.add(amount);
            setBalance(msg.sender, balanceOf(msg.sender).add(amount));
        } else {
            // if enough, just swap then
            uint256 yCrvWillGet = get_yCrvFromUsdt(amount);
            IERC20(yCrvToken).transfer(msg.sender, yCrvWillGet);
        }
    }

    function mint() public {
        uint256 yCrvBalanceBeforeMint = IERC20(yCrvToken).balanceOf(address(this));
        // Minting now
        // I don't know how to set this val
        uint256 min_mint_amount = 0;

        IUSDT(USDT).approve(yDeposit, unmintedUSDT);

        IyDeposit(yDeposit).add_liquidity([
            0,
            0,
            unmintedUSDT,
            0
        ], min_mint_amount);

        // After Add Liquidity and get yCrv, setting counters
        uint256 justMinted_yCrv = IERC20(yCrvToken).balanceOf(address(this)).sub(yCrvBalanceBeforeMint);
        mintedUSDT = mintedUSDT.add(unmintedUSDT);
        unmintedUSDT = 0;
        minted_yCRV = minted_yCRV.add(justMinted_yCrv);
    }

    function withdraw() public {
        // yCrv balance of this contract
        uint256 ycrvBalance = IERC20(yCrvToken).balanceOf(address(this));
        uint256 usdtBalance = balanceOf(msg.sender);
        require(usdtBalance != 0, "You don't have balance to withdraw");
        // 1 USDT will likely smaller than 1 yCRV
        // If there are 2 yCrv, and msg.sender want to withdraw 1 yCrv, then no minting required.
        // If no enough yCrv able to withdraw, then trying to mint.
        if (usdtBalance > ycrvBalance) {
           mint();
        }
        uint256 converted = get_yCrvFromUsdt(usdtBalance);
        // Will revert if there are not enough yCrv in contract though
        bool isTransferOk = IERC20(yCrvToken).transfer(msg.sender, converted);
        require(isTransferOk, "No enough yCrv in the contract. Please contract Dev team asap.");
        setBalance(msg.sender, 0);
    }
}