// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

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

interface IListRegistry {
    function isAdmin(address) external returns (bool);

    function isInBlacklist(address) external returns (bool);
}

contract MatatakiPeggedTokenFactoryV2 is Ownable {
    IMatatakiPeggedTokenFactory public peggedTokenFactoryV1;

    bytes32 public DOMAIN_SEPARATOR;
    address public managerRegistry;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address token,uint8 decimals,uint32 tokenId)");

    mapping(uint32 => address) public tokenIdToAddress;

    constructor(address theOldFactory, address _managerRegistry) public {
        peggedTokenFactoryV1 = IMatatakiPeggedTokenFactory(theOldFactory);
        managerRegistry = _managerRegistry;
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("MatatakiPeggedTokenFactoryV2")),
                keccak256(bytes("1")),
                _chainId,
                address(this)
            )
        );
    }

    function computeAddress(string calldata _name, string calldata _symbol)
        public
        view
        returns (address predictedAddress)
    {
        return peggedTokenFactoryV1.computeAddress(_name, _symbol);
    }

    function newAPeggedToken(
        string calldata name,
        string calldata symbol,
        uint32 tokenId,
        uint8 decimals,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            tokenIdToAddress[tokenId] == address(0),
            "Token have been created"
        );

        address recoveredAddress =
            whoSignIt(name, symbol, tokenId, decimals, v, r, s);
        bool isPermitSignerAdmin =
            IListRegistry(managerRegistry).isAdmin(recoveredAddress);
        require(
            // Permit signer must be the admin in the manager Registry
            recoveredAddress != address(0) && isPermitSignerAdmin,
            "MatatakiPeggedTokenFactoryV2::INVALID_SIGNATURE: Please request new permit or contact us."
        );
        // Create it if signature was right
        // Symbol check was done on the factory v1
        peggedTokenFactoryV1.newAPeggedToken(name, symbol, decimals);
        address computedAddress =
            peggedTokenFactoryV1.computeAddress(name, symbol);
        tokenIdToAddress[tokenId] = computedAddress;
    }

    function tokenCreationCode() external view returns (bytes memory) {
        return peggedTokenFactoryV1.tokenCreationCode();
    }

    function transferOwnerOfV1To(address to) public onlyOwner {
        Ownable(address(peggedTokenFactoryV1)).transferOwnership(to);
    }

    function setToken(uint32 id, address token) public onlyOwner {
        require(tokenIdToAddress[id] == address(0), "Token have been created");
        tokenIdToAddress[id] = token;
    }

    function whoSignIt(
        string calldata name,
        string calldata symbol,
        uint32 tokenId,
        uint8 decimals,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (address recoveredAddress) {
        address token = computeAddress(name, symbol);
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(PERMIT_TYPEHASH, token, decimals, tokenId)
                    )
                )
            );
        recoveredAddress = ecrecover(digest, v, r, s);
    }
}
