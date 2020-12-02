pragma solidity >=0.4.21 <0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20WithPermit {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface Burnable {
    function burn(address account, uint256 amount) external;
}

interface IMatatakiPeggedTokenFactory {
    function allPeggedTokens() external returns(address[] memory);
    function symbolToAddress(string calldata) external returns(address);
    function computeAddress(string calldata _name, string calldata _symbol)
        external
        view
        returns (address predictedAddress);
}

interface IERC20Detailed {
    function name() external returns(string memory);
    function symbol() external returns(string memory);
}

contract MatatakiTokenBurner {
    address public factory;
    event BurnFanPiao(address indexed tokenAddress, uint256 indexed uid, uint256 value);

    constructor(address _factory) public {
        factory = _factory;
    }

    modifier isMatatakiPeggedToken(address _token) {
        IERC20Detailed erc20 = IERC20Detailed(_token);
        string memory name = erc20.name();
        string memory symbol = erc20.symbol();
        address computed = IMatatakiPeggedTokenFactory(factory).computeAddress(name, symbol);
        address registered = IMatatakiPeggedTokenFactory(factory).symbolToAddress(symbol);
        require(registered != address(0) && computed == registered, "MatatakiTokenBurner::BAD_TOKEN: Failed to lookup");
        _;
    }

    function burn(
        address token,
        uint256 uid,
        uint256 value
    ) public isMatatakiPeggedToken(token) {
        IERC20(token).transferFrom(msg.sender, address(this), value); // send value to us
        // burn value in our contract, the contract have to to be admin
        Burnable(token).burn(address(this), value);
        emit BurnFanPiao(token, uid, value);
    }

    function burnWithPermit(
        address token,
        uint256 uid,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // equal of approve, with offline signature
        IERC20WithPermit(token).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        burn(token, uid, value);
    }
}
