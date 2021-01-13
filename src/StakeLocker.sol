pragma solidity ^0.6;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MatatakiStakingLocker is Ownable {
    using SafeMath for uint256;

    // Owner can set this to allow people to extract funds
    bool public emergencyButton = false;

    address public stakingToken;
    uint256 public lockPeriod = 30 days;
    mapping(address=>uint256) public balanceOf;
    mapping(address=>uint256) public lockExpiry;
    event Staked(address indexed who, uint256 amount);
    event Unstaked(address indexed who, uint256 amount);

    constructor(address _stakingToken, address _manager) public {
        stakingToken = _stakingToken;
        transferOwnership(_manager);
    }

    /** Management */
    function adjustLockPeriod(uint _days) public onlyOwner {
        lockPeriod = _days * 1 days;
    }

    function tapEmergencyButton() public onlyOwner {
        emergencyButton = !emergencyButton;
    }

    /** Staking */
    modifier isGoodToUnstake() {
        bool isExpired = block.timestamp > lockExpiry[msg.sender];
        require(emergencyButton || isExpired, "STAKE_NOT_EXPIRED: Your stake was not expired.");
        _;
    }

    function stake(uint256 amount) public {
        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        lockExpiry[msg.sender] = block.timestamp + lockPeriod;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) public isGoodToUnstake {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        IERC20(stakingToken).transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function extendLockdown() public {
        require(balanceOf[msg.sender] > 0, "NO_STAKE: You don't have stake");
        lockExpiry[msg.sender] = block.timestamp + lockPeriod;
    }
}