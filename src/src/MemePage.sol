// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";

contract MemePage is Ownable {
    struct Likes {
        uint64 likesCount;
        mapping(address => bool) likesMap;
        address[] likes;
    }
    
    struct Comment {
        uint64 id;
        address author;
        string content;
        uint64 time;
        uint64 editTime;
        Likes likes;
    }
    
    struct Post {
        uint64 id;
        address author;
        uint64 time;
        bytes content;
        Likes likes;
        Comment[] comments;
        mapping(uint64 => uint64) commentsMap;
    }

    Post[] internal _posts;
    mapping(uint64 => uint64) _postIndex;
    uint64 internal _likeFee;
    uint64 internal _commentFee;
    uint64 internal _postId = 1;
    uint64 internal _commentId = 1;

    function _find(address[] memory list, address item) internal pure returns(uint64) {
        for (uint64 i = 0; i < list.length; i++) {
            if (list[i] == item) {
                return i;
            }
        }
        return -1;
    }

    function _removeLike(uint64 postId, address item) internal {
        uint64 index = _find(_posts[_postIndex[postId]].likes, item);
        if (index == -1) {
            return;
        }
        if (index == _posts[_postIndex[postId]].likes.length - 1) {
            uint64 _ = _posts[_postIndex[postId]].likes.pop();
        } else {
            _posts[_postIndex[postId]].likes[index] = _posts[_postIndex[postId]].likes[_posts[_postIndex[postId]].likes.length - 1];
            uint64 _ = _posts[_postIndex[postId]].likes.pop();
        }
    }

    function _removeComment(uint64 postId, uint64 commentId) internal {
        uint64 index = _posts[_postIndex[postId]].commentsMap[commentId];
        if (index == _posts[_postIndex[postId]].comments.length - 1) {
            uint64 _ = _posts[_postIndex[postId]].comments.pop();
        } else {
            _posts[_postIndex[postId]].comments[index] = _posts[_postIndex[postId]].comments[_posts[_postIndex[postId]].comments.length - 1];
            uint64 _ = _posts[_postIndex[postId]].comments.pop();
        }
    }

    function _removePost(uint64 index) internal {
        if (index == _posts[_postIndex[index]].length - 1) {
            uint64 _ = _posts[_postIndex[index]].pop();
        } else {
            _posts[_postIndex[index]][index] = _posts[_postIndex[index]][_posts[_postIndex[index]].length - 1];
            uint64 _ = _posts[_postIndex[index]].pop();
        }
    }

    function _addPost(bytes content) internal {
        uint64 postId = _postId;
        _postIndex[_postId] = _posts.length;
        Post memory post;
        post.id = postId;
        post.author = msg.sender;
        post.time = block.timestamp;
        post.content = content;
        _posts.push(post);
        _postId++;
    }

    function _addComment(string memory content, uint64 postId) internal {
        Post memory post = _posts[_postIndex[postId]];
        require(post.author == msg.sender, "Wrong sender");
        require(post.id == postId, "Post does not exist");
        Comment memory comment;
        comment.id = _commentId;
        comment.author = msg.sender;
        comment.time = block.timestamp;
        comment.content = content;
        post.commentsMap[post.comments.length] = _commentId;
        post.comments.push(comment);
        _commentId++;
    }

    function _addLike(Likes memory like) internal {
        require(!like.likesMap[msg.sender], "Liked already");
        like.likes.push(msg.sender);
        like.likesMap[msg.sender] = true;
        like.likesCount++;
    }

    function _addLike(address like, uint64 postId) internal {
        Post memory post = _posts[_postIndex[postId]];
        _addLike(post.likes);
    }

    function _addLike(address like, uint64 postId, uint64 commentId) internal {
        Post memory post = _posts[_postIndex[postId]];
        Comment memory comment = post.comments[post.commentsMap[commentId]];
        _addLike(comment.likes);
    }

    constructor(ENS ens, string memory name, bytes32 addressReverseNode) {
        if (address(ens) != address(0)) {
            ReverseRegistrar reverseRegistrar = ReverseRegistrar(ens.owner(addressReverseNode));
            reverseRegistrar.claim(address(this));
            reverseRegistrar.setName(name);
        }
    }
}