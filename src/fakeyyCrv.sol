// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FakeYYCrv is ERC20 {
    IERC20 yCrv;
    constructor(address _ycrv) public ERC20("Fake yyCrv", "FyyCrv") {
        yCrv = IERC20(_ycrv);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "stake amount must be greater than 0");
        yCrv.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external {
        require(_amount > 0, "unstake shares must be greater than 0");
        _burn(msg.sender, _amount);
        yCrv.transfer(msg.sender, _amount);
    }
}