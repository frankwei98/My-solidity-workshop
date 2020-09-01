// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BasicToken is ERC20 {
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {
        // MINT THEM TO THE MAX OF UINT256 YEAH!
        _mint(msg.sender, uint256(-1));
    }
}