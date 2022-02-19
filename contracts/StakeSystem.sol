// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "hardhat/console.sol";

contract StakingSystem is Ownable, ERC721Holder {
    IERC20 public rewardsToken;
    IERC721 public nft;

    uint256 public stakedTotal;
    uint256 public stakingStartTime;
    uint256 constant stakingTime = 180 seconds;
    // uint256 public totalUnclaimedRewards;
    uint256 constant token = 10e18;
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => int256) tokenStakingCoolDown;
        mapping(uint256 => uint256) tokenIndex;
        uint256 balance;
        uint256 rewardsEarned;
        uint256 rewardsReleased;
    }

    constructor(IERC721 _nft, IERC20 _rewardsToken) {
        nft = _nft;
        rewardsToken = _rewardsToken;
    }

    /// @notice mapping of a staker to its current properties
    mapping(address => Staker) public stakers;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public tokenOwner;
    bool public tokensClaimable;
    bool initialised;

    event Staked(address owner, uint256 amount);

    /// @notice event emitted when a user has unstaked a token
    event Unstaked(address owner, uint256 amount);

    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user, uint256 reward);

    /// @notice Allows reward tokens to be claimed
    event ClaimableStatusUpdated(bool status);

    /// @notice Emergency unstake tokens without rewards
    event EmergencyUnstake(address indexed user, uint256 tokenId);

    function initStaking() public onlyOwner {
        //needs access control
        require(!initialised, "Already initialised");
        stakingStartTime = block.timestamp;
        initialised = true;
    }

    function setTokensClaimable(bool _enabled) public onlyOwner {
        //needs access control
        tokensClaimable = _enabled;
        emit ClaimableStatusUpdated(_enabled);
    }

    function getStakedTokens(address _user)
        public
        view
        returns (uint256[] memory tokenIds)
    {
        return stakers[_user].tokenIds;
    }

    function stake(uint256 tokenId) public {
        _stake(msg.sender, tokenId);
    }

    function stakeBatch(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i]);
        }
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(initialised, "Staking System: the staking has not started");
        require(
            nft.ownerOf(_tokenId) == _user,
            "user must be the owner of the token"
        );
        Staker storage staker = stakers[_user];

        staker.tokenIds.push(_tokenId);
        staker.tokenIndex[staker.tokenIds.length - 1];
        staker.tokenStakingCoolDown[_tokenId] = int256(block.timestamp);
        tokenOwner[_tokenId] = _user;
        nft.safeTransferFrom(_user, address(this), _tokenId);

        emit Staked(_user, _tokenId);
        stakedTotal++;
    }

    function unstake(uint256 _tokenId) public {
        claimReward(msg.sender);
        _unstake(msg.sender, _tokenId);
    }

    function unstakeBatch(uint256[] memory tokenIds) public {
        claimReward(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenOwner[tokenIds[i]] == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }

    // Unstake without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstake(uint256 _tokenId) public {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "nft._unstake: Sender must have staked tokenID"
        );
        _unstake(msg.sender, _tokenId);
        emit EmergencyUnstake(msg.sender, _tokenId);
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            tokenOwner[_tokenId] == _user,
            "Nft Staking System: user must be the owner of the staked nft"
        );
        Staker storage staker = stakers[_user];

        uint256 lastIndex = staker.tokenIds.length - 1;
        uint256 lastIndexKey = staker.tokenIds[lastIndex];
        staker.tokenIds[staker.tokenIndex[_tokenId]] = lastIndexKey;
        staker.tokenIndex[lastIndexKey] = staker.tokenIndex[_tokenId];
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
            delete staker.tokenIndex[_tokenId];
        }
        staker.tokenStakingCoolDown[_tokenId] = -1;
        if (staker.balance == 0) {
            delete stakers[_user];
        }
        delete tokenOwner[_tokenId];

        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId);
        stakedTotal--;
    }

    function updateReward(address _user) public {
        Staker storage staker = stakers[_user];
        uint256[] storage ids = staker.tokenIds;
        console.log("cooldown before loop");
        for (uint256 i = 0; i < ids.length; i++) {
            if (
                staker.tokenStakingCoolDown[ids[i]] <
                int256(block.timestamp + stakingTime) &&
                staker.tokenStakingCoolDown[ids[i]] >= 0
            ) {
                console.log("conditional");
                /// @notice that something here is triggering a payable transaction...
                console.log("cooldown in loop and conditional:");

                // uint256 stakedDays = (uint(staker.tokenStakingCoolDown[ids[i]]) - block.timestamp) / stakingTime;
                // uint256 partialTime = (uint(staker.tokenStakingCoolDown[ids[i]] ) - block.timestamp) % stakingTime;

                // .................................................

                // staker.balance =  token * stakedDays;

                // staker.tokenStakingCoolDown[ids[i]] = int(block.timestamp + partialTime);
            }
        }
    }

    function claimReward(address _user) public {
        require(tokensClaimable == true, "Tokens cannnot be claimed yet");
        updateReward(_user);

        Staker storage staker = stakers[_user];

        staker.rewardsEarned -= staker.balance;
        staker.rewardsReleased += staker.balance;
        rewardsToken.transfer(_user, staker.balance);

        emit RewardPaid(_user, staker.balance);
    }
}
