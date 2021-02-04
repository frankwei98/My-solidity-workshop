// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// Uniswap
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract LoanSwap is IUniswapV2Callee {
    using SafeERC20 for IERC20;

    uint256 constant deadline = 1 days;
    address public owner;

    modifier isOwner() {
        require(owner == msg.sender, "You have to be the owner to call this");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    // in case of emergency
    function _withdraw(
        address token,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
    }

    function withdraw(address token, uint256 amount) external isOwner {
        _withdraw(token, owner, amount);
    }

    function withdrawAll(address token) external isOwner {
        _withdraw(token, owner, IERC20(token).balanceOf(address(this)));
    }

    function uniswapV2Call(
        address sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external override {
        address[] memory path = new address[](2);
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;

        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        require(_amount0 == 0 || _amount1 == 0);

        path[0] = _amount0 == 0 ? token1 : token0;
        path[1] = _amount0 == 0 ? token0 : token1;

        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
        (address router1, address router2) =
            abi.decode(_data, (address, address));
        address factoryOfRouter1 = IUniswapV2Router02(router1).factory();
        address factoryOfPair = IUniswapV2Pair(msg.sender).factory();
        require(factoryOfRouter1 == factoryOfPair, "Different factory");

        token.approve(router2, amountToken);

        // no need for require() check, if amount required is not sent, Router will revert
        uint256 amountRequired =
            IUniswapV2Router02(router1).getAmountsIn(amountToken, path)[0];
        uint256 amountReceived =
            IUniswapV2Router02(router2).swapExactTokensForTokens(
                amountToken,
                amountRequired,
                path,
                msg.sender,
                deadline
            )[1];

        // return tokens to V2 pair
        token.transfer(msg.sender, amountRequired);
        // YEAHH PROFIT
        token.safeTransfer(owner, amountReceived - amountRequired);
    }
}
