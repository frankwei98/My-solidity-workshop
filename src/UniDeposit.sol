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
    
    //uint256 public minted_yCRV; // yCRV minted for now, can cal the price with mintedUSDT

//    address public yDeposit = address("0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3");
    address public yDeposit;

    constructor(address _usdt, address _ycrv, address _depositContract) public {
        USDT = _usdt;
        yCrvToken = _ycrv;
        yDeposit = _depositContract;
        IUSDT(USDT).approve(yDeposit, uint(-1));
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

    function unminted_USDT() view public returns (uint) {
        return IERC20(USDT).balanceOf(address(this));
    }    
    function minted_yCRV() view public returns (uint) {
        return IERC20(yCrvToken).balanceOf(address(this));
    }
    function get_yCrvFromUsdt(uint256 amount) public view returns (uint256) {
        return amount.mul(minted_yCRV()).div(mintedUSDT);
    }
    function get_usdtFromYcrv(uint256 amount) public view returns (uint256) {
        return amount.mul(mintedUSDT).div(minted_yCRV());
    }    

    event Deposit(address indexed who, uint256 amountOfUsdt);

    function deposit(uint256 input) external goodToChargeUSDT(input) {
        // sadly no return from USDT
        IUSDT(USDT).transferFrom(msg.sender, address(this), input);
        if (input > mintedUSDT) {
            // New Deposit goes to unmintedUSDT pool
            setBalance(msg.sender, balanceOf(msg.sender).add(input));
            emit Deposit(msg.sender, input);
        } else {
            // if enough, just swap then
            uint256 output = get_yCrvFromUsdt(input);
            mintedUSDT = mintedUSDT.sub(input);            
            IERC20(yCrvToken).transfer(msg.sender, output);
        }
    }

    function withdraw(uint input) external {
        uint ycrv = minted_yCRV();
        require(input <= ycrv, "Insufficient minted yCrv.");
        uint output = get_usdtFromYcrv(input);
        mintedUSDT = mintedUSDT.sub(output);
        IERC20(yCrvToken).transferFrom(msg.sender, address(this), input);
        IUSDT(USDT).transfer(msg.sender, output);
    }

    // The world could always use more heroes.
    function mint() public {
        IyDeposit(yDeposit).add_liquidity([0,0,unminted_USDT(),0], 0);
    }

    function claim() public {
        // yCrv balance of this contract
        uint256 ycrvBalance = minted_yCRV();
        uint256 usdtBalance = balanceOf(msg.sender);
        require(usdtBalance != 0, "You don't have balance to withdraw");
        uint ycrvRequirement = get_yCrvFromUsdt(usdtBalance);

        // 1 USDT will likely smaller than 1 yCRV
        // If there are 2 yCrv, and msg.sender want to withdraw 1 yCrv, then no minting required.
        // If no enough yCrv able to withdraw, then trying to mint.
        if (ycrvRequirement > ycrvBalance) {
           mint();
        }
        ycrvRequirement = get_yCrvFromUsdt(usdtBalance);
        // Will revert if there are not enough yCrv in contract though
        bool isTransferOk = IERC20(yCrvToken).transfer(msg.sender, ycrvRequirement);
        require(isTransferOk, "No enough yCrv in the contract. Please contract Dev team asap."); 
        // minakokojima: should it failed inside the transfer call?
        setBalance(msg.sender, 0);
    }
}