// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeERC721 {
    IERC20 public rewardToken;
    IERC20 public DAI;
    IERC721 public boredApe;

    uint256 constant SECONDS_PER_YEAR = 31536000;

    struct User {
        uint256 stakedAmount;
        uint256 startTime;
        uint256 rewardAccrued;
    }

    mapping(address => User) user;
    error tryAgain();

    address admin;

    constructor() {
        boredApe =IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
        DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier boredApeHolder() {
        uint balance = boredApe.balanceOf(msg.sender);
        require(balance > 0, "not a bored ape owner");
        _;
    }
    function setTokenAddress(address _tokenAddress) public onlyAdmin {
        rewardToken = IERC20(_tokenAddress);
    }

    function stake(uint amount) external boredApeHolder {
        User storage _user = user[msg.sender];
        uint256 _amount = _user.stakedAmount;

        DAI.transferFrom(msg.sender, address(this), amount);

        if (_amount == 0) {
            _user.stakedAmount = amount;
            _user.startTime = block.timestamp;
        } else {
            updateReward();
            _user.stakedAmount += amount;
        }
    }

    function updateReward() public {
        User storage _user = user[msg.sender];
        uint256 _reward = calcReward();
        _user.rewardAccrued += _reward;
        _user.startTime = block.timestamp;
    }

    function calcReward() public view returns (uint256 _reward) {
        User storage _user = user[msg.sender];

        uint256 _amount = _user.stakedAmount;
        uint256 _startTime = _user.startTime;
        uint256 duration = block.timestamp - _startTime;

        _reward = (duration * 20 * _amount) / (SECONDS_PER_YEAR * 100);
    }

    function claimReward(uint256 amount) public {
        User storage _user = user[msg.sender];
        updateReward();
        uint256 _claimableReward = _user.rewardAccrued;
        require(_claimableReward >= amount, "insufficient funds");
        _user.rewardAccrued -= amount;
        if (amount > rewardToken.balanceOf(address(this))) revert tryAgain();
        rewardToken.transfer(msg.sender, amount);
    }

    function withdrawStaked(uint256 amount) public {
        User storage _user = user[msg.sender];
        uint256 staked = _user.stakedAmount;
        require(staked >= amount, "insufficient fund");
        updateReward();
        _user.stakedAmount -= amount;
        DAI.transfer(msg.sender, amount);
    }

    function closeAccount() external {
        User storage _user = user[msg.sender];
        uint256 staked = _user.stakedAmount;
        withdrawStaked(staked);
        uint256 reward = _user.rewardAccrued;
        claimReward(reward);
    }

    function displayReward() public view returns(uint256) {
        User storage _user = user[msg.sender];
        uint256 rewarded = _user.rewardAccrued;
        return rewarded;
    }

    function userInfo(address _user) external view returns (User memory) {
        return user[_user];
    }
}