// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

interface IBlacklistManager {
    function isAdmin(address) external returns (bool);

    function isInBlacklist(address) external returns (bool);
}

contract BlacklistManager {
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isInBlacklist;
    event Enlist(address operator, address[] list, uint256 datetime);
    event Delist(address operator, address[] list, uint256 datetime);
    event HandoverAdmin(address from, address to);

    constructor() public {
        isAdmin[msg.sender] = true;
    }

    modifier onlyAdmins() {
        require(isAdmin[msg.sender], "You're not the admin");
        _;
    }

    function handoverPermission(address to) public onlyAdmins {
        isAdmin[to] = true;
        isAdmin[msg.sender] = false;
        emit HandoverAdmin(msg.sender, to);
    }

    function revoke(address who) public onlyAdmins {
        isAdmin[who] = false;
    }

    function setAdmin(address _new) public onlyAdmins {
        isAdmin[_new] = true;
    }

    function enlistPeoples(address[] memory list) public onlyAdmins {
        for (uint8 i = 0; i < list.length; i++) {
            address who = list[i];
            isInBlacklist[who] = true;
        }
        emit Enlist(msg.sender, list, block.timestamp);
    }

    function delistPeoples(address[] memory list) public onlyAdmins {
        for (uint8 i = 0; i < list.length; i++) {
            address who = list[i];
            isInBlacklist[who] = false;
        }
        emit Delist(msg.sender, list, block.timestamp);
    }
}
