// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IListRegistry {
    function isAdmin(address) external returns (bool);
    function isInBlacklist(address) external returns (bool);
}

interface MintableERC20 {
    function mint(address account, uint256 amount) external;
}

contract PeggedTokenMinter is Ownable {
    bytes32 public DOMAIN_SEPARATOR;
    address public managerRegistry;
    // Token => To Wallet => Sequence Number, we just use nonces to avoid replay attack
    mapping(address => mapping(address => uint256)) nonces;
    bytes32
        public constant
        PERMIT_TYPEHASH = keccak256("Permit(address token,address to,uint256 value,uint256 nonce,uint256 deadline)");
    constructor(address _managerRegistry) public {
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
                keccak256(bytes("PeggedTokenMinter")),
                keccak256(bytes("1")),
                _chainId,
                address(this)
            )
        );
    }

    function updateManagerRegistry(address _managerRegistry) public onlyOwner() {
        managerRegistry = _managerRegistry;
    }

    function mintPeggedTokenWithPermit(
        address token,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "SelfMintManager::Permit: Permit EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        token,
                        to,
                        value,
                        nonces[token][to]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        bool isPermitSignerAdmin = IListRegistry(managerRegistry).isAdmin(recoveredAddress);
        require(
            // Mint Permit signer must be the admin in the manager Registry
            recoveredAddress != address(0) && isPermitSignerAdmin,
            "SelfMintManager::INVALID_SIGNATURE: Please request new permit or contact us."
        );
        // Mint if call successfully
        MintableERC20(token).mint(to, value);
    }

    function getNoncesOf(address tokenToMint, address who) public view returns (uint256) {
        return nonces[tokenToMint][who];
    }
}