// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;
// only use ABIEncoderV2 to return rich data, no worry
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract ERC20Faucet {
    using Address for address;
    mapping(address => bool) isListCurator;
    mapping(address => bool) isListedToken;
    address[] tokens;

    constructor(address[] memory addresses) public {
        isListCurator[msg.sender] = true;
        for (uint256 i = 0; i < addresses.length; i++) {
            tokens.push(addresses[i]);
            isListedToken[addresses[i]] = true;
        }
    }

    modifier onlyCurator() {
        require(isListCurator[msg.sender], "You have to be the curator to continue.");
        _;
    }

    function addCurator(address newCurator) public onlyCurator {
        isListCurator[newCurator] = true;
    }

    function batchAddCurator(address[] memory addresses) public onlyCurator {
        for (uint256 i = 0; i < addresses.length; i++) {
            isListCurator[addresses[i]] = true;
        }
    }

    function removeCurator(address guy) public onlyCurator {
        isListCurator[guy] = false;
    }

    modifier goodToChargeToken(address tokenContract, uint256 amount) {
        require(IERC20(tokenContract).balanceOf(msg.sender) >= amount, "You don't have that much balance for us");
        require(IERC20(tokenContract).allowance(msg.sender, address(this)) >= amount, "You need to approve first before deposit");
        _;
    }

    // anyone can deposit, as long as token was on the list
    function deposit(address tokenContract, uint256 amount) public
    goodToChargeToken(tokenContract, amount) returns(bool result)
    {
        require(isListedToken[tokenContract], "Sorry, but this token was not on the list");
        result = IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);
        return result;
    }

    event Claimed(address token, address who, uint256 amount);

    function claim(address _token, uint256 amount) public {
        require(isListedToken[_token], "Sorry, but this token was not on the list");
        require(IERC20(_token).balanceOf(address(this)) > amount, "We don't have that much");
        require(amount <= 1 ether, "That's too much to ask");
        IERC20(_token).transfer(msg.sender, amount);
        emit Claimed(_token, msg.sender, amount);
    }

    function claimAll() public {
        // send 10^18 of every token to anybody!
        for (uint256 i = 0; i < tokens.length; i++) {
            // 1 ether = 10^18
            if (IERC20(tokens[i]).balanceOf(address(this)) > 1 ether)
            {
                // in case that some token impl throw error that might cause error
                IERC20(tokens[i]).transfer(msg.sender, 1 ether);
                emit Claimed(tokens[i], msg.sender, 1 ether);
            }
        }
    }

    struct TokenBalance {
        address token;
        uint256 balance;
    }

    function balances() public view returns(TokenBalance[] memory details) {
        details = new TokenBalance[](tokens.length);
        address _this = address(this);
        for (uint256 i = 0; i < tokens.length; i++) {
            details[i] = TokenBalance(tokens[i], IERC20(tokens[i]).balanceOf(_this));
        }
        return details;
    }

    event Enlist(address tokenContract, address by);

    function _enlist(address tokenContract) internal {
        isListedToken[tokenContract] = true;
        tokens.push(tokenContract);
        emit Enlist(tokenContract, msg.sender);
    }

    function enlist(address tokenContract) public onlyCurator {
        require(tokenContract.isContract(), "This address is not a contract");
        _enlist(tokenContract);
    }
}