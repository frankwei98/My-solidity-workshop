// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IyDeposit.sol";
import "./IUSDT.sol";
import "./TokenThatAnyoneCanMint.sol";

interface ITokenThatAnyoneCanMint {
    function mint(uint256 amount) external;
}

contract FakeYDeposit {
    using SafeMath for uint256;
    address yCrvToken;
    address usdt;
    function getyCrv() public view returns(address) {
        return yCrvToken;
    }
    function getUsdt() public view returns(address) {
        return usdt;
    }
    uint256 constant public digitsBetweenUsdtAndyCrv = 10 ** (18-6);

    constructor(address fakeUsdt, address fakeyCrv) public {
        // TokenThatAnyoneCanMint fakeyCrv = new TokenThatAnyoneCanMint("Fake yCrv", "FyCrv", 18);
        // TokenThatAnyoneCanMint fakeUsdt = new TokenThatAnyoneCanMint("Fake USDT", "FUSDT", 6);
        yCrvToken = address(fakeyCrv);
        usdt = address(fakeUsdt);
    }

    function add_liquidity(uint256[4] calldata uamounts, uint256 min_mint_amount) external {
        uint256 usdtAmount = uamounts[2];
        IUSDT(usdt).transferFrom(msg.sender, address(this), usdtAmount);
        uint256 yCrvGet = usdtAmount.mul(95).div(100).mul(digitsBetweenUsdtAndyCrv); // pretend to be 95% of USDT in term of qty
        TokenThatAnyoneCanMint(yCrvToken).mint(msg.sender, yCrvGet);
    }

    function usdtTap(uint256 amount) public {
        TokenThatAnyoneCanMint(usdt).mint(msg.sender, amount);
    }
}