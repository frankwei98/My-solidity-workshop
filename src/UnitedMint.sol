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
    using SafeMath for uint256;

    address public USDT;
    address public yCrv;
    address public yyCrv;
    address public yDeposit;

    //    address constant public USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    //    address constant public yCrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    //  address constant public yyCrv = address(0x199ddb4BDF09f699d2Cf9CA10212Bd5E3B570aC2);
    //  address constant public yDeposit = address(0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3);

    mapping(address => uint256) _balance; // unminted USDT

    function setBalance(address who, uint256 amount) internal {
        _balance[who] = amount;
    }

    function balanceOf(address who) public view returns (uint256) {
        return _balance[who];
    }

    uint256 public mintedUSDT; // USDT involved in minting yCRV

    constructor(
        address _usdt,
        address _ycrv,
        address _depositContract,
        address _yyCrv
    ) public {
        USDT = _usdt;
        yCrv = _ycrv;
        yDeposit = _depositContract;
        yyCrv = _yyCrv;
        IUSDT(USDT).approve(yDeposit, uint256(-1));
        IERC20(yCrv).approve(yyCrv, uint256(-1));
    }

    function unminted_USDT() public view returns (uint256) {
        return IERC20(USDT).balanceOf(address(this));
    }

    function minted_yCRV() public view returns (uint256) {
        return IERC20(yCrv).balanceOf(address(this));
    }

    function minted_yyCRV() public view returns (uint256) {
        return IERC20(yyCrv).balanceOf(address(this));
    }

    function get_yyCrvFromUsdt(uint256 amount) public view returns (uint256) {
        return amount.mul(minted_yyCRV()).div(mintedUSDT);
    }

    function get_usdtFromYycrv(uint256 amount) public view returns (uint256) {
        return amount.mul(mintedUSDT).div(minted_yyCRV());
    }

    event Deposit(address indexed who, uint256 usdt);
    event Claim(address indexed who, uint256 usdt, uint256 yyCrv);
    event Withdraw(address indexed who, uint256 yyCrv, uint256 usdt);

    /**
     * @dev Deposit usdt or claim yyCrv directly if balance of yyCrv is sufficient
     */
    function deposit(uint256 input) external {
        require(input != 0, "Empty usdt");
        IUSDT(USDT).transferFrom(msg.sender, address(this), input);
        if (input > mintedUSDT) {
            setBalance(msg.sender, balanceOf(msg.sender).add(input));
            emit Deposit(msg.sender, input);
        } else {
            uint256 output = get_yyCrvFromUsdt(input);
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
        IyDeposit(yDeposit).add_liquidity([0, 0, unminted_USDT(), 0], 0);
        IyyCrv(yyCrv).stake(minted_yCRV());
    }

    /**
     * @dev Claim yyCrv back, if the balance is sufficient, execute mint()
     */
    function claim() public {
        uint256 input = balanceOf(msg.sender);
        require(input != 0, "You don't have USDT balance to withdraw");
        uint256 r; // requirement yCrv
        if (mintedUSDT == 0) {
            mint();
            r = get_yyCrvFromUsdt(input);
        } else {
            r = get_yyCrvFromUsdt(input);
            if (r > minted_yyCRV()) mint();
            r = get_yyCrvFromUsdt(input);
        }
        IERC20(yyCrv).transfer(msg.sender, r);
        setBalance(msg.sender, 0);
        emit Claim(msg.sender, input, r);
    }

    /**
     * @dev Try to claim unminted usdt by yyCrv if the balance is sufficient
     */
    function withdraw(uint256 input) external {
        require(input != 0, "Empty yyCrv");
        require(input <= minted_yyCRV(), "Insufficient minted yyCrv.");
        uint256 output = get_usdtFromYycrv(input);
        mintedUSDT = mintedUSDT.add(output);
        IERC20(yyCrv).transferFrom(msg.sender, address(this), input);
        IUSDT(USDT).transfer(msg.sender, output);
        emit Withdraw(msg.sender, input, output);
    }

    /**
     * @dev Deposit usdt and claim yyCrv in any case
     */
    function depositAndClaim(uint256 input) external {
        require(input != 0, "Empty usdt");
        IUSDT(USDT).transferFrom(msg.sender, address(this), input);
        if (input > mintedUSDT) {
            mint();
        }
        uint256 output = get_yyCrvFromUsdt(input);
        mintedUSDT = mintedUSDT.sub(input);
        IERC20(yyCrv).transfer(msg.sender, output);
        emit Claim(msg.sender, input, output);
    }
}
