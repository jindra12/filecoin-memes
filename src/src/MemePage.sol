// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";

interface MemePageStructs {
    struct Likes {
        uint64 likesCount;
        address[] likes;
    }
    
    struct Comment {
        uint64 id;
        address author;
        string content;
        uint256 time;
        uint256 editTime;
        Likes likes;
    }
    
    struct Post {
        uint64 id;
        address author;
        uint256 time;
        uint256 editTime;
        bytes content;
        Likes likes;
        Comment[] comments;
        mapping(uint64 => uint64) commentsMap;
    }
}

contract MemePage is Ownable {
    mapping(uint64 => mapping(address => bool)) internal _likesMap;
    mapping(uint64 => mapping(uint64 => uint64)) internal _commentsMap;
    mapping(uint64 => uint64) internal _postsMap;

    Post[] internal _posts;
    mapping(uint64 => uint64) _postIndex;

    uint64 internal _postId = 1;
    uint64 internal _commentIDId = 1;

    function _removeLike(Likes memory like) internal {
        for (uint64 i = 0; i < like.likes.length; i++) {
            if (like.likes[i] == msg.sender) {
                like.likesMap[msg.sender] = false;
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

    function _addPost(bytes memory content) internal {
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

    function _editPost(bytes memory content, uint64 postId) internal {
        Post memory post = _posts[_postIndex[postId]];
        require(post.author == msg.sender, "Wrong sender");
        require(post.id == postId, "Post does not exist");
        post.content = content;
        post.editTime = block.timestamp;
    }

    function _removePost(uint64 postId) internal {
        uint64 index = _postIndex[postId];
        Post memory post = _posts[index];
        require(post.author == msg.sender);
        require(post.id == postId, "Post does not exist");
        if (index == _posts.length - 1) {
            _postIndex[postId] = 0;
            _posts.pop();
        } else {
            _posts[index] = _posts[_posts.length - 1];
            _postIndex[postId] = 0;
            _postIndex[_posts[index].id] = index;
            _posts.pop();
        }
    }

    function _addComment(string memory content, uint64 postId) internal {
        Post memory post = _posts[_postIndex[postId]];
        Comment memory comment;
        comment.id = _commentId;
        comment.author = msg.sender;
        comment.time = block.timestamp;
        comment.content = content;
        _commentsMap[postId][_commentId] = posts.comments.length;
        post.comments.push(comment);
        _commentId++;
    }

    function _editComment(string memory content, uint64 postId, uint64 commentId) internal {
        uint64 index = _commentsMap[postId][commentId];
        Comment memory comment = _posts[_postIndex[postId]].comments[index];
        require(comment.author == msg.sender, "Wrong sender");
        require(comment.id == commentId, "Comment does not exist");
        comment.editTime = block.timestamp;
        comment.content = content;
    }

    function _removeComment(uint64 postId, uint64 commentId) internal {
        uint64 postIndex = _postIndex[postId];
        uint64 index = _commentsMap[postId][commentId];
        Comment memory comment = _posts[postIndex].comments[index];
        require(comment.author == msg.sender, "Wrong sender");
        require(comment.id == commentId, "Comment does not exist");
        if (index == _posts[postIndex].comments.length - 1) {
            _posts[postIndex].comments.pop();
        } else {
            _posts[postIndex].comments[index] = _posts[postIndex].comments[_posts[postIndex].comments.length - 1];
            _commentsMap[postId][_posts[postIndex].comments[index].id] = index;
            _posts[postIndex].comments.pop();
        }
        _commentsMap[postId][commentId] = 0;
    }

    function _addLike(uint64 postId, Likes memory like) internal {
        require(!like.likesMap[msg.sender], "Liked already");
        like.likes.push(msg.sender);
        
        like.likesCount++;
    }

    function _addLike(uint64 postId) internal {
        Post memory post = _posts[_postIndex[postId]];
        _addLike(post.likes);
    }

    function _addLike(uint64 postId, uint64 commentId) internal {
        Post memory post = _posts[_postIndex[postId]];
        Comment memory comment = post.comments[post.commentsMap[commentId]];
        _addLike(comment.likes);
    }

    function _removeLike(uint64 postId) internal {
        Post memory post = _posts[_postIndex[postId]];
        _removeLike(post.likes);
    }

    function _removeLike(uint64 postId, uint64 commentId) internal {
        Post memory post = _posts[_postIndex[postId]];
        Comment memory comment = post.comments[post.commentsMap[commentId]];
        _removeLike(comment.likes);
    }

    function _comparePostsByTime(Post memory a, Post memory b) internal pure returns(bool) {
        return b.time >= a.time;
    }

    function _comparePostsByHot(Post memory a, Post memory b) internal pure returns(bool) {
        return (b.time * b.likes.likesCount) >= (a.time * a.likes.likesCount);
    }

    function _comparePostsByLike(Post memory a, Post memory b) internal pure returns(bool) {
        return b.likes.likesCount >= a.likes.likesCount;
    }

    function _comparePosts(Post memory a, Post memory b, uint64 kind) internal pure returns(bool) {
        if (kind == 0) {
            return _comparePostsByTime(a, b);
        } else if (kind == 1) {
            return _comparePostsByHot(a, b);
        } else {
            return _comparePostsByLike(a, b);
        }
    }

    function _compareCommentsByTime(Comment memory a, Comment memory b) internal pure returns(bool) {
        return b.time >= a.time;
    }

    function _compareCommentsByHot(Comment memory a, Comment memory b) internal pure returns(bool) {
        return (b.time * b.likes.likesCount) >= (a.time * a.likes.likesCount);
    }

    function _compareCommentsByLike(Comment memory a, Comment memory b) internal pure returns(bool) {
        return b.likes.likesCount >= a.likes.likesCount;
    }

    function _compareComments(Comment memory a, Comment memory b, uint64 kind) internal pure returns(bool) {
        if (kind == 0) {
            return _compareCommentsByTime(a, b);
        } else if (kind == 1) {
            return _compareCommentsByHot(a, b);
        } else {
            return _compareCommentsByLike(a, b);
        }
    }

    constructor(ENS ens, string memory name, bytes32 addressReverseNode) {
        if (address(ens) != address(0)) {
            ReverseRegistrar reverseRegistrar = ReverseRegistrar(ens.owner(addressReverseNode));
            reverseRegistrar.claim(address(this));
            reverseRegistrar.setName(name);
        }
    }
}