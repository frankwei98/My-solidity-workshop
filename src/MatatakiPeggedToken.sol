// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC20WithPermit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AddressRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MatatakiPeggedToken is ERC20WithPermit {
    address public factory;
    // A Contract that manage blacklist
    address public addressRegistry;

    constructor(string memory _name, string memory _symbol)
        public
        ERC20WithPermit(_name, _symbol)
    {
        factory = msg.sender;
    }

    modifier adminOnly() {
        require(
            IMatatakiAddressRegistry(addressRegistry).isAdmin(msg.sender),
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

        bool isFromBanned = IMatatakiAddressRegistry(addressRegistry).isInBlacklist(
            from
        );
        bool isToBanned = IMatatakiAddressRegistry(addressRegistry).isInBlacklist(to);
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

    function initialize(address _newaddressRegistry, uint8 _decimals) public {
        require(
            addressRegistry == address(0),
            "MatatakiPeggedToken::INIT_BL: Blacklist Manager is existed already"
        );
        require(
            _newaddressRegistry != address(0),
            "MatatakiPeggedToken::INIT_BL: New Blacklist Manager can not be ZERO"
        );
        addressRegistry = _newaddressRegistry;
        _setupDecimals(_decimals);
    }

    function updateTheBlacklistMgr(address _newaddressRegistry) public {
        require(
            addressRegistry != address(0) && addressRegistry == msg.sender,
            "MatatakiPeggedToken::MUST_BE_BL_MGR: You must be the manager to update"
        );
        addressRegistry = _newaddressRegistry;
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
    address public addressRegistry;
    address[] public allPeggedTokens;
    mapping(string => address) public symbolToAddress;
    bytes32 constant salt = keccak256("Matataki Pegged Token");

    event NewPeggedToken(
        string indexed name,
        string indexed symbol,
        address tokenAddress
    );

    constructor(address registry) public {
        addressRegistry = registry;
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
        _token.initialize(addressRegistry, _decimals);
        symbolToAddress[_symbol] = address(_token);
        allPeggedTokens.push(address(_token));
        emit NewPeggedToken(_name, _symbol, address(_token));
    }

    function tokenCreationCode() public override view returns (bytes memory) {
        return type(MatatakiPeggedToken).creationCode;
    }
}
