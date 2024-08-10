// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControlEnumerable} from "../lib/openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import {MemeStorage} from "./MemeStorage.sol";
import {MemeEvents} from "./MemeEvents.sol";
import {MemeStructs} from "./MemeStructs.sol";
import {MemeLibrary} from "./MemeLibrary.sol";

abstract contract MemeComments is Ownable,AccessControlEnumerable,MemeStructs,MemeEvents,MemeStorage {
    function _getNewestComments(uint256 postId, uint256 skip, uint256 limit) internal view returns(Comment[] memory,uint256) {
        uint256[] memory ids = _posts[_postIndex[postId]].commentIds;
        Comment[] memory comments = new Comment[](limit);
        uint256 resultIndex = 0;
        uint256 start = ids.length - 1;
        if (skip >= start) {
            return (comments,0);
        }
        for (uint256 i = start - skip; i >= 0; i--) {
            comments[resultIndex] = _comments[_commentIndex[ids[i]]];
            resultIndex++;
            if (resultIndex == limit) {
                return (comments,i);
            }
        }
        return (comments,0);
    }

    function _filterCommentsBy(uint256 postId, uint256 kind, uint256 skip, uint256 limit) internal view returns (Comment[] memory,uint256) {
        Comment[] memory comments = new Comment[](limit);
        uint256 resultIndex = 0;
        uint256 timeUnit = kind == 1 ? MemeLibrary.getDay() : kind == 2 ? MemeLibrary.getWeek() : MemeLibrary.getMonth(); 
        uint256[] memory ids = kind == 1 ? _commentToday[postId][timeUnit] : kind == 2 ? _commentWeek[postId][timeUnit] : _commentMonth[postId][timeUnit];
        uint256 start = ids.length - 1;
        if (skip >= start) {
            return (comments,0);
        }
        for (uint256 i = start - skip; i >= 0; i--) {
            uint256 commentIndex = _commentIndex[ids[i]];
            comments[resultIndex] = _comments[commentIndex];
            resultIndex++;
            if (resultIndex == limit) {
                return (comments,i);
            }
        }
         
        return (comments,0);
    }

    function addComment(string memory content, uint256 postId) public {
        Comment memory comment;
        comment.id = _commentId;
        comment.author = msg.sender;
        comment.time = block.timestamp;
        comment.content = content;

        _commentIndex[_commentId] = _comments.length;
        _comments.push(comment);

        _commentToday[MemeLibrary.getDay()][postId].push(_commentId);
        _commentToday[MemeLibrary.getWeek()][postId].push(_commentId);
        _commentToday[MemeLibrary.getMonth()][postId].push(_commentId);

        _commentId++;
    }

    function editComment(string memory content, uint256 commentId) public {
        Comment storage comment = _comments[_commentIndex[_commentId]];
        require(comment.author == msg.sender || owner() == msg.sender, "Wrong sender");
        require(comment.id == commentId, "Comment does not exist");
        comment.editTime = block.timestamp;
        comment.content = content;
    }

    function removeComment(uint256 commentId) public {
        uint256 index = _commentIndex[_commentId];
        Comment storage comment = _comments[index];
        require(comment.author == msg.sender || owner() == msg.sender, "Wrong sender");
        require(comment.id == commentId, "Comment does not exist");
        if (index == _comments.length - 1) {
            _comments.pop();
            _commentIndex[comment.id] = 0;
        } else {
            _comments[index] = _comments[_comments.length - 1];
            _comments.pop();
            _commentIndex[comment.id] = 0;
            _commentIndex[_comments[index].id] = index;
        }
    }

    function getComments(uint256 postId, uint256 filter, uint256 order, uint256 skip, uint256 limit) public view returns(Comment[] memory,uint256) {
        (Comment[] memory comments,uint256 skipped) = filter == 0 ? _getNewestComments(postId, skip, limit) : _filterCommentsBy(postId, filter, skip, limit);
        return (MemeLibrary.mergeSortComments(comments, order),skipped);
    }

    function getComment(uint256 commentId) public view returns(Comment memory) {
        return _comments[_commentIndex[commentId]];
    }
}