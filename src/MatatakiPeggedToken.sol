// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC20WithPermit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BlacklistManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MatatakiPeggedToken is ERC20WithPermit {
    address public factory;
    // A Contract that manage blacklist
    address public blacklistManager;

    constructor(string memory _name, string memory _symbol)
        public
        ERC20WithPermit(_name, _symbol)
    {
        factory = msg.sender;
    }

    modifier adminOnly() {
        require(
            IBlacklistManager(blacklistManager).isAdmin(msg.sender),
            "MatatakiPeggedToken::ADMIN_ONLY: Matataki Admin only action "
        );
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        bool isFromBanned = IBlacklistManager(blacklistManager).isInBlacklist(
            from
        );
        bool isToBanned = IBlacklistManager(blacklistManager).isInBlacklist(to);
        require(
            !isFromBanned,
            "MatatakiPeggedToken::FROM_IN_BLACKLIST: The from wallet was banned. Please contact Matataki Team ASAP."
        );
        require(
            !isToBanned,
            "MatatakiPeggedToken::TO_IN_BLACKLIST: The to wallet was banned. Please contact Matataki Team ASAP."
        );
    }

    function operatorSend(
        address from,
        address to,
        uint256 value
    ) public adminOnly {
        // We run this service, we have the right as a operator
        _transfer(from, to, value);
    }

    function mint(address account, uint256 amount) public adminOnly {
        // New Token coming in this world
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public adminOnly {
        // Token getting out to another world
        _burn(account, amount);
    }

    function initialize(address _newblacklistManager, uint8 _decimals) public {
        require(
            blacklistManager == address(0),
            "MatatakiPeggedToken::INIT_BL: Blacklist Manager is existed already"
        );
        require(
            _newblacklistManager != address(0),
            "MatatakiPeggedToken::INIT_BL: New Blacklist Manager can not be ZERO"
        );
        blacklistManager = _newblacklistManager;
        _setupDecimals(_decimals);
    }

    function updateTheBlacklistMgr(address _newblacklistManager) public {
        require(
            blacklistManager != address(0) && blacklistManager == msg.sender,
            "MatatakiPeggedToken::MUST_BE_BL_MGR: You must be the manager to update"
        );
        blacklistManager = _newblacklistManager;
    }
}

interface IMatatakiPeggedTokenFactory {
    function computeAddress(string calldata _name, string calldata _symbol)
        external
        view
        returns (address predictedAddress);

    function newAPeggedToken(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals
    ) external;

    function tokenCreationCode() external view returns (bytes memory);
}

contract MatatakiPeggedTokenFactory is Ownable, IMatatakiPeggedTokenFactory {
    address public blacklistManager;
    address[] public allPeggedTokens;
    mapping(string => address) public symbolToAddress;
    bytes32 constant salt = keccak256("Matataki Pegged Token");

    event NewPeggedToken(
        string indexed name,
        string indexed symbol,
        address tokenAddress
    );

    function initBlacklistManager(address where) public onlyOwner() {
        require(address(0) == blacklistManager, "Blacklist manager is existed");
        blacklistManager = where;
    }

    function computeCreationCodeWithArgs(
        string memory _name,
        string memory _symbol
    ) public view returns (bytes memory result) {
        result = abi.encodePacked(
            tokenCreationCode(),
            abi.encode(_name, _symbol)
        );
    }

    function computeAddress(string memory _name, string memory _symbol)
        public
        override
        view
        returns (address predictedAddress)
    {
        /// This complicated expression just tells you how the address
        /// can be pre-computed. It is just there for illustration.
        /// You actually only need ``new D{salt: salt}(arg)``.
        predictedAddress = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        address(this),
                        salt,
                        keccak256(computeCreationCodeWithArgs(_name, _symbol))
                    )
                )
            )
        );
    }

    function newAPeggedToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public override onlyOwner() {
        require(symbolToAddress[_symbol] == address(0), "Token have been created on this factory");
        MatatakiPeggedToken _token = new MatatakiPeggedToken{salt: salt}(
            _name,
            _symbol
        );
        _token.initialize(blacklistManager, _decimals);
        symbolToAddress[_symbol] = address(_token);
        allPeggedTokens.push(address(_token));
        emit NewPeggedToken(_name, _symbol, address(_token));
    }

    function tokenCreationCode() public override view returns (bytes memory) {
        return type(MatatakiPeggedToken).creationCode;
    }
}
