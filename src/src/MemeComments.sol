// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControlEnumerable} from "../lib/openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import {MemeReply} from "./MemeReply.sol";
import {MemeEvents} from "./MemeEvents.sol";
import {MemeStructs} from "./MemeStructs.sol";
import {MemeLibrary} from "./MemeLibrary.sol";

abstract contract MemeComments is Ownable,AccessControlEnumerable,MemeStructs,MemeEvents,MemeReply {
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

    function _filterCommentsBy(uint256 postId, FilterType kind, uint256 skip, uint256 limit) internal view returns (Comment[] memory,uint256) {
        Comment[] memory comments = new Comment[](limit);
        uint256 resultIndex = 0;
        uint256 timeUnit = kind == FilterType.DAY ? MemeLibrary.getDay() : kind == FilterType.WEEK ? MemeLibrary.getWeek() : MemeLibrary.getMonth(); 
        uint256[] memory ids = kind == FilterType.DAY ? _commentToday[postId][timeUnit] : kind == FilterType.WEEK ? _commentWeek[postId][timeUnit] : _commentMonth[postId][timeUnit];
        uint256 start = ids.length - 1;
        uint256 giveUpCount = 0;
        if (skip >= start) {
            return (comments,0);
        }
        for (uint256 i1 = start - skip + 1; i1 > 0; i1--) {
            uint256 i = i1 - 1;
            uint256 commentIndex = _commentIndex[ids[i]];
            Comment memory c = _comments[commentIndex];
            if (c.id == ids[i]) {
                comments[resultIndex] = c;
                resultIndex++;
                if (resultIndex == limit) {
                    return (comments,i);
                }
            }
            if (giveUpCount >= _giveUpLimit) {
                return (comments,i);
            }
            giveUpCount++;
        }
         
        return (comments,0);
    }

    function addComment(string memory content, uint256 postId, uint256 replyToId, ReplyToType replyToType) public returns(uint256) {
        _verifyReply(replyToType, replyToId);

        Comment memory comment;
        comment.id = _commentId;
        comment.author = msg.sender;
        comment.time = block.timestamp;
        comment.content = content;
        comment.replyTo.id = replyToId;
        comment.replyTo.replyType = replyToType;

        _commentIndex[_commentId] = _comments.length;
        _comments.push(comment);

        _commentToday[MemeLibrary.getDay()][postId].push(_commentId);
        _commentWeek[MemeLibrary.getWeek()][postId].push(_commentId);
        _commentMonth[MemeLibrary.getMonth()][postId].push(_commentId);

        uint256 currentId = _commentId;

        _commentId++;

        emit CommentAdded(postId, currentId);

        return currentId;
    }

    function editComment(string memory content, uint256 commentId, uint256 replyToId, ReplyToType replyToType) public {
        _verifyReply(replyToType, replyToId);

        Comment storage comment = _comments[_commentIndex[_commentId]];
        require(comment.author == msg.sender || owner() == msg.sender || hasRole(MOD_ROLE, msg.sender), "Wrong sender");
        require(comment.id == commentId, "Comment does not exist");
        comment.editTime = block.timestamp;
        comment.content = content;
        comment.replyTo.id = replyToId;
        comment.replyTo.replyType = replyToType;
        emit CommentEdited(commentId);
    }

    function removeComment(uint256 commentId) public {
        uint256 index = _commentIndex[_commentId];
        Comment storage comment = _comments[index];
        require(comment.author == msg.sender || owner() == msg.sender || hasRole(MOD_ROLE, msg.sender), "Wrong sender");
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
        emit CommentRemoved(commentId, msg.sender);
    }

    function getComment(uint256 commentId) public view returns(Comment memory) {
        return _comments[_commentIndex[commentId]];
    }

    function getComments(uint256 postId, FilterType filter, SortType order, uint256 skip, uint256 limit) public view returns(Comment[] memory,uint256) {
        (Comment[] memory comments,uint256 skipped) = filter == FilterType.LATEST ? _getNewestComments(postId, skip, limit) : _filterCommentsBy(postId, filter, skip, limit);
        return (MemeLibrary.mergeSortComments(comments, order),skipped);
    }
}