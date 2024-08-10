// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControlEnumerable} from "../lib/openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import {MemeStorage} from "./MemeStorage.sol";
import {MemeEvents} from "./MemeEvents.sol";
import {MemeStructs} from "./MemeStructs.sol";
import {MemeLibrary} from "./MemeLibrary.sol";

abstract contract MemePayout is Ownable,AccessControlEnumerable,MemeStructs,MemeEvents,MemeStorage {
    function _distributeReward(address author) internal {
        _authorsFees[author] += _likeFee - _likeFeeProfit - _likeAdminProfit;
        _ownerFees += _likeFeeProfit;
        address adminToReward = _getAndMoveAdminRewarded();
        _adminFees[adminToReward] += _likeAdminProfit;
    }

    function _distributeRewardPost(uint256 postId) internal {
        _distributeReward(_posts[_postIndex[postId]].author);
    }

    function _distributeRewardComment(uint256 commentId) internal {
        _distributeReward(_comments[_commentIndex[commentId]].author);
    }

    function _getAndMoveAdminRewarded() internal returns(address) {
        uint256 adminCount = getRoleMemberCount(MOD_ROLE);
        uint256 current = _currentAdminRewardIndex;
        _currentAdminRewardIndex = (_currentAdminRewardIndex + 1) % adminCount;
        return getRoleMember(MOD_ROLE, current);
    }

    function withdrawOwner() public onlyOwner() {
        require(_ownerFees > 0, "Nothing to withdraw");
        (bool ok,) = owner().call{ value: _ownerFees }("");
        require(ok, "Transaction failed");
        _ownerFees = 0;
    }

    function withdrawAuthor() public {
        require(_authorsFees[msg.sender] > 0, "Nothing to withdraw");
        (bool ok,) = msg.sender.call{ value: _authorsFees[msg.sender] }("");
        require(ok, "Transaction failed");
        _authorsFees[msg.sender] = 0;
    }

    function withdrawAdmin() public onlyRole(MOD_ROLE) {
        require(_adminFees[msg.sender] > 0, "Nothing to withdraw");
        (bool ok,) = msg.sender.call{ value: _adminFees[msg.sender] }("");
        require(ok, "Transaction failed");
        _adminFees[msg.sender] = 0;
    }

    function getWithdrawableOwner() public view returns(uint256) {
        return _ownerFees;
    }

    function getWithdrawableAuthor() public view returns(uint256) {
        return _authorsFees[msg.sender];
    }

    function getWithdrawableAdmin() public view onlyRole(MOD_ROLE) returns(uint256) {
        return _adminFees[msg.sender];
    }
}