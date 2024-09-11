// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControlEnumerable} from "../lib/openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import {MemeLibrary} from "./MemeLibrary.sol";
import {MemeEvents} from "./MemeEvents.sol";
import {MemeStorage} from "./MemeStorage.sol";
import {MemeStructs} from "./MemeStructs.sol";

abstract contract MemeLikes is Ownable,AccessControlEnumerable,MemeStructs,MemeEvents,MemeStorage {
    function _addLike(uint256 postId) internal {
        require(!_likesMap[postId][msg.sender], "Liked already");
        _likesMap[postId][msg.sender] = true;
        _posts[_postIndex[postId]].likes.likesCount++;
        emit AddLike(postId);
    }

    function _addLike(uint256 postId, uint256 commentId) internal {
        require(!_likesCommentsMap[postId][commentId][msg.sender], "Liked already");
        _likesCommentsMap[postId][commentId][msg.sender] = true;
        _comments[_commentIndex[commentId]].likes.likesCount++;
        emit AddLikeComment(postId, commentId);
    }

    function removeLike(uint256 postId) public {
        require(_likesMap[postId][msg.sender], "Not liked before");
        _likesMap[postId][msg.sender] = false;
        _posts[_postIndex[postId]].likes.likesCount--;
        emit RemoveLike(postId);
    }

    function removeLike(uint256 postId, uint256 commentId) public {
        require(_likesCommentsMap[postId][commentId][msg.sender], "Not liked before");
        _likesCommentsMap[postId][commentId][msg.sender] = false;
        _comments[_commentIndex[commentId]].likes.likesCount--;
        emit RemoveLikeComment(postId, commentId);
    }

    function getLiked(uint256 postId) public view returns(bool) {
        return _likesMap[postId][msg.sender];
    }

    function getLikedComment(uint256 postId, uint256 commentId) public view returns(bool) {
        return _likesCommentsMap[postId][commentId][msg.sender];
    }

    function getLikeFee() public view returns(uint256) {
        return _likeFee;
    }

    function getLikeFeeProfit() public view returns(uint256) {
        return _likeFeeProfit;
    }

    function getAdminFee() public view returns(uint256) {
        return _likeAdminProfit;
    }

    function setAdminFee(uint256 fee) public onlyOwner() {
        require(_likeFee > _likeFeeProfit + fee, "Invalid fees for likes");
        _likeAdminProfit = fee;
        emit SetAdminLikeFee(fee);
    }

    function setLikeFee(uint256 fee) public onlyOwner() {
        require(fee > _likeFeeProfit + _likeAdminProfit, "Invalid fees for likes");
        _likeFee = fee;
        emit SetLikeFee(fee);
    }

    function setLikeFeeProfit(uint256 fee) public onlyOwner() {
        require(_likeFee > fee + _likeAdminProfit, "Invalid fees for likes");
        _likeFeeProfit = fee;
        emit SetLikeFeeProfit(fee);
    }
}