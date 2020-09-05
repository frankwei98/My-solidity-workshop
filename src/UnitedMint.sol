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

contract UnitedMint {
    using SafeMath for uint;

    address public USDT;
    address public yCrv;
    address public yyCrv;  
    address public yDeposit;

//    address constant public USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
//    address constant public yCrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
//  address constant public yyCrv = address(0x199ddb4BDF09f699d2Cf9CA10212Bd5E3B570aC2);
//  address constant public yDeposit = address(0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3);
  
    mapping(address=>uint) _balance; // unminted USDT

    function setBalance(address who, uint amount) internal {
        _balance[who] = amount;
    }
    function balanceOf(address who) public view returns (uint) {
        return _balance[who];
    }

    uint public mintedUSDT; // USDT involved in minting yCRV

    constructor(address _usdt, address _ycrv, address _depositContract) public {
        USDT = _usdt;
        yCrv = _ycrv;
        yDeposit = _depositContract;
        IUSDT(USDT).approve(yDeposit, uint(-1));
        IERC20(yCrv).approve(yyCrv, uint(-1));        
    }

    function unminted_USDT() view public returns (uint) {
        return IERC20(USDT).balanceOf(address(this));
    }    
    function minted_yCRV() view public returns (uint) {
        return IERC20(yCrv).balanceOf(address(this));
    }
    function minted_yyCRV() view public returns (uint) {
        return IERC20(yyCrv).balanceOf(address(this));
    }
    function get_yyCrvFromUsdt(uint amount) public view returns (uint) {
        return amount.mul(minted_yyCRV()).div(mintedUSDT);
    }
    function get_usdtFromYycrv(uint amount) public view returns (uint) {
        return amount.mul(mintedUSDT).div(minted_yyCRV());
    }    

    event Deposit(address indexed who, uint usdt);
    event Claim(address indexed who, uint usdt, uint yyCrv);
    event Withdraw(address indexed who, uint yyCrv, uint usdt);

    /**
     * @dev Deposit usdt or claim yyCrv directly if balance of yyCrv is sufficient
     */
    function deposit(uint input) external {
        require(input != 0, "Empty usdt");        
        IUSDT(USDT).transferFrom(msg.sender, address(this), input);
        if (input > mintedUSDT) {
            setBalance(msg.sender, balanceOf(msg.sender).add(input));
            emit Deposit(msg.sender, input);
        } else {
            uint output = get_yyCrvFromUsdt(input);
            mintedUSDT = mintedUSDT.sub(input);
            IERC20(yyCrv).transfer(msg.sender, output);
            emit Claim(msg.sender, input, output);
        }
    }

    /**
     * @dev Mint all unminted_USDT into yyCrv
     */
    function mint() public {
        require(unminted_USDT() > 0, "Empty usdt");
        mintedUSDT = mintedUSDT.add(unminted_USDT());
        IyDeposit(yDeposit).add_liquidity([0,0,unminted_USDT(),0], 0);
        IyyCrv(yyCrv).stake(minted_yCRV());
    }

    /**
     * @dev Claim yyCrv back, if the balance is sufficient, execute mint()
     */
    function claim() public {
        uint input = balanceOf(msg.sender);
        require(input != 0, "You don't have USDT balance to withdraw");
        uint r; // requirement yCrv
        if (mintedUSDT == 0) {
            mint();
            r = get_yyCrvFromUsdt(input);
        } else {
            r = get_yyCrvFromUsdt(input);
            if (r > minted_yyCRV()) mint(); 
            r = get_yyCrvFromUsdt(input);
        }
        mintedUSDT = mintedUSDT.sub(input);        
        IERC20(yyCrv).transfer(msg.sender, r);
        setBalance(msg.sender, 0);
        emit Claim(msg.sender, input, r);
    }

    /**
     * @dev Try to claim unminted usdt by yyCrv if the balance is sufficient
     */
    function withdraw(uint input) external {
        require(input != 0, "Empty yyCrv");
        require(input <= minted_yyCRV(), "Insufficient minted yyCrv.");
        uint output = get_usdtFromYycrv(input);
        mintedUSDT = mintedUSDT.add(output);
        IERC20(yyCrv).transferFrom(msg.sender, address(this), input);
        IUSDT(USDT).transfer(msg.sender, output);
        emit Withdraw(msg.sender, input, output);
    }    

    /**
     * @dev Deposit usdt and claim yyCrv in any case
     */
    function depositAndClaim(uint input) external {
        require(input != 0, "Empty usdt");        
        IUSDT(USDT).transferFrom(msg.sender, address(this), input);
        if (input > mintedUSDT) {
            mint();
        }
        uint output = get_yyCrvFromUsdt(input);
        mintedUSDT = mintedUSDT.sub(input);
        IERC20(yyCrv).transfer(msg.sender, output);
        emit Claim(msg.sender, input, output);
    }
}