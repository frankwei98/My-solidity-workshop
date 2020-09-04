// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;
// only use ABIEncoderV2 to return rich data, no worry
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IyDeposit.sol";
import "./IUSDT.sol";
import "./IyyCrv.sol";

/**
 * UniMint - Deposit USDT and Mint yCRV together
 */

contract UniDeposit {
    using SafeMath for uint256;

    address public USDT;
    address public yCrv;
    address public yyCrv;    

//  address public yDeposit = address("0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3");
//  address constant public yyCrv = address("0x199ddb4BDF09f699d2Cf9CA10212Bd5E3B570aC2");
    address public yDeposit;    

    mapping(address=>uint256) _balance; // unminted USDT

    function setBalance(address who, uint256 amount) internal {
        _balance[who] = amount;
    }
    function balanceOf(address who) public view returns (uint256) {
        return _balance[who];
    }

    uint256 public mintedUSDT; // USDT involved in minting yCRV

    constructor(address _usdt, address _ycrv, address _depositContract) public {
        USDT = _usdt;
        yCrv = _ycrv;
        yDeposit = _depositContract;
        IUSDT(USDT).approve(yDeposit, uint(-1));
    }

    function unminted_USDT() view public returns (uint) {
        return IERC20(USDT).balanceOf(address(this));
    }    
    function minted_yCRV() view public returns (uint) {
        return IERC20(yCrv).balanceOf(address(this));
    }
    function yyCRV() view public returns (uint) {
        return IERC20(yyCrv).balanceOf(address(this));
    }
    function get_yCrvFromUsdt(uint256 amount) public view returns (uint256) {
        return amount.mul(minted_yCRV()).div(mintedUSDT);
    }
    function get_usdtFromYcrv(uint256 amount) public view returns (uint256) {
        return amount.mul(mintedUSDT).div(minted_yCRV());
    }    

    event Deposit(address indexed who, uint256 amountOfUsdt);

    function deposit(uint256 input) external {
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
            IERC20(yCrv).transfer(msg.sender, output);
        }
    }

    function withdraw(uint input) external {
        uint ycrv = minted_yCRV();
        require(input <= ycrv, "Insufficient minted yCrv.");
        uint output = get_usdtFromYcrv(input);
        mintedUSDT = mintedUSDT.sub(output);
        IERC20(yCrv).transferFrom(msg.sender, address(this), input);
        IUSDT(USDT).transfer(msg.sender, output);
    }

    // The world could always use more heroes.
    function mint() public {
        IyDeposit(yDeposit).add_liquidity([0,0,unminted_USDT(),0], 0);
        IyyCrv(yyCrv).stake(minted_yCRV());
    }

    function claim() public {
        uint256 usdtBalance = balanceOf(msg.sender);
        require(usdtBalance != 0, "You don't have USDT balance to withdraw");       
        uint r; // requirement yCrv
        if (mintedUSDT == 0) {
            mint();
            r = get_yCrvFromUsdt(usdtBalance);
        } else {
            r = get_yCrvFromUsdt(usdtBalance);
            if (r > minted_yCRV()) mint(); 
            r = get_yCrvFromUsdt(usdtBalance);
        }   
        IERC20(yCrv).transfer(msg.sender, r);
        setBalance(msg.sender, 0);
    }
}