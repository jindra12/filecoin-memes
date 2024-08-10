// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControlEnumerable} from "../lib/openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import {MemeLibrary} from "./MemeLibrary.sol";
import {MemeTags} from "./MemeTags.sol";
import {MemePayout} from "./MemePayout.sol";

abstract contract MemeLikes is Ownable,AccessControlEnumerable,MemePayout,MemeTags {
    function _removeLike(Likes storage like) internal {
        for (uint256 i = 0; i < like.likes.length; i++) {
            if (like.likes[i] == msg.sender) {
                like.likesCount--;
                if (i == like.likes.length - 1) {
                    like.likes.pop();
                } else {
                    like.likes[i] = like.likes[like.likes.length - 1];
                    like.likes.pop();
                }
            }
        }
    }

    function addLike(uint256 postId) public payable {
        require(!_likesMap[postId][msg.sender], "Liked already");
        require(msg.value == _likeFee, "Not enough value");
        Post storage post = _posts[_postIndex[postId]];
        post.likes.likes.push(msg.sender);
        _likesMap[postId][msg.sender] = true;
        post.likes.likesCount++;

        for (uint256 i = 0; i < post.tagIds.length; i++) {
            Tag memory tag;
            tag.name = _tagNames[post.tagIds[i]];
            tag.hash = post.tagIds[i];
            _addTag(tag);
        }

        _authorsFees[post.author] += _likeFee - _likeFeeProfit;
        _ownerFees += _likeFeeProfit;
    }

    function addLike(uint256 postId, uint256 commentId) public payable {
        require(!_likesCommentsMap[postId][commentId][msg.sender], "Liked already");
        require(msg.value == _likeFee, "Not enough value");
        Comment storage comment = _comments[_commentIndex[commentId]];
        comment.likes.likes.push(msg.sender);
        _likesCommentsMap[postId][commentId][msg.sender] = true;
        comment.likes.likesCount++;

        _authorsFees[comment.author] += _likeFee - _likeFeeProfit - _likeAdminProfit;
        _ownerFees += _likeFeeProfit;

        address adminToReward = _getAndMoveAdminRewarded();
        _adminFees[adminToReward] += _likeAdminProfit;
    }

    function removeLike(uint256 postId) public {
        Post storage post = _posts[_postIndex[postId]];
        require(_likesMap[postId][msg.sender], "Not liked before");
        _likesMap[postId][msg.sender] = false;
        _removeLike(post.likes);
    }

    function removeLike(uint256 postId, uint256 commentId) public {
        Comment storage comment = _comments[_commentIndex[commentId]];
        require(_likesCommentsMap[postId][commentId][msg.sender], "Not liked before");
        _likesCommentsMap[postId][commentId][msg.sender] = false;
        _removeLike(comment.likes);
    }

    function getLikeFee() public view returns(uint256) {
        return _likeFee;
    }

    function getLikeFeeProfit() public view returns(uint256) {
        return _likeFeeProfit;
    }

    function getAdminFee() public view returns(uint256) {
        return _adminFees;
    }

    function setAdminFee(uint256 fee) public onlyOwner() returns(uint256) {
        require(_likeFee > _likeFeeProfit + fee, "Invalid fee for likes");
        _likeAdminProfit = fee;
    }

    function setLikeFee(uint256 fee) public onlyOwner() {
        require(fee > _likeFeeProfit + _likeAdminProfit, "Invalid fees for likes");
        _likeFee = fee;
    }

    function setLikeFeeProfit(uint256 fee) public onlyOwner() {
        require(_likeFee > fee + _likeAdminProfit, "Invalid fees for likes");
        _likeFeeProfit = fee;
    }
}