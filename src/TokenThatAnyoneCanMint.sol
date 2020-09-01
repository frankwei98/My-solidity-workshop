// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenThatAnyoneCanMint is ERC20 {
    address public creator;
    constructor(string memory name, string memory symbol, uint8 decimals)
    public ERC20(name, symbol) {
        creator = msg.sender;
        _setupDecimals(decimals);
        uint256 oneUnit = (10 ** uint(decimals));
        _mint(msg.sender, oneUnit);
    }

    function mint(uint256 amount) public {
        // If new _totalSupply overflow, SafeMath in _mint() should be revert
        _mint(msg.sender, amount);
    }
}