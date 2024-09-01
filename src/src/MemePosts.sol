// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControlEnumerable} from "../lib/openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import {MemeReply} from "./MemeReply.sol";
import {MemeEvents} from "./MemeEvents.sol";
import {MemeStructs} from "./MemeStructs.sol";
import {MemeLibrary} from "./MemeLibrary.sol";
import {MemeTags} from "./MemeTags.sol";

abstract contract MemePosts is Ownable,AccessControlEnumerable,MemeStructs,MemeEvents,MemeReply {
    function _filterPostByTags(Post memory post, uint256[] memory tagHashes) internal view returns(bool) {
        if (tagHashes.length == 0) {
            return true;
        }
        for (uint256 j = 0; j < tagHashes.length; j++) {
            if (_postsByTag[tagHashes[j]][post.id]) {
                return true;
            }
        }
        return false;
    }

    function _getNewestByAuthor(address author) internal view returns(Post[] memory) {
        uint256[] memory ids = _postsByAuthor[author];
        Post[] memory posts = new Post[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            posts[i] = _posts[_postIndex[ids[i]]];
        }
        return posts;
    }

    function _getNewestPosts(uint256 skip, uint256 limit, uint256[] memory tagHashes, address author) internal view returns (Post[] memory,uint256) {
        Post[] memory viablePosts = author == address(0) ? _posts : _getNewestByAuthor(author);
        Post[] memory posts = new Post[](limit);
        uint256 resultIndex = 0;
        uint256 start = viablePosts.length - 1;
        uint256 giveUpCount = 0;
        if (skip >= start) {
            return (posts,0);
        }
        for (uint256 i = start - skip; i >= 0; i--) {
            if (_filterPostByTags(viablePosts[i], tagHashes) && MemeLibrary.filterPostByAuthor(viablePosts[i], author)) {
                posts[resultIndex] = viablePosts[i];
                resultIndex++;
                if (resultIndex == limit) {
                    return (posts,i);
                }
            }
            if (giveUpCount >= _giveUpLimit) {
                return (posts,i);
            }
            giveUpCount++;
        }
        return (posts,0);
    }

    function _filterPostsBy(FilterType kind, uint256 skip, uint256 limit, uint256[] memory tagHashes, address author) internal view returns (Post[] memory,uint256) {
        Post[] memory posts = new Post[](limit);
        uint256 resultIndex = 0;
        uint256 timeUnit = kind == FilterType.DAY ? MemeLibrary.getDay() : kind == FilterType.WEEK ? MemeLibrary.getWeek() : MemeLibrary.getMonth(); 
        uint256[] memory ids = kind == FilterType.DAY ? _postToday[timeUnit] : kind == FilterType.WEEK ? _postWeek[timeUnit] : _postMonth[timeUnit];
        uint256 start = ids.length - 1;
        uint256 giveUpCount = 0;
        if (skip >= start) {
            return (posts,0);
        }
        for (uint256 i = start - skip; i >= 0; i--) {
            uint256 index = _postIndex[ids[i]];
            if (_filterPostByTags(_posts[index], tagHashes) && MemeLibrary.filterPostByAuthor(_posts[index], author)) {
                posts[resultIndex] = _posts[index];
                resultIndex++;
                if (limit == resultIndex) {
                    return (posts,i);
                }
            }
            if (giveUpCount >= _giveUpLimit) {
                return (posts,i);
            }
            giveUpCount++;
        }

        return (posts,0);
    }

    function _addPost(string memory title, string memory content, uint256 replyToId, ReplyToType replyToType) internal returns(uint256) {
        _verifyReply(replyToType, replyToId);

        uint256 postId = _postId;
        _postIndex[_postId] = _posts.length;
        Post memory post;
        post.id = postId;
        post.author = msg.sender;
        post.time = block.timestamp;
        post.title = title;
        post.content = content;
        post.replyTo.id = replyToId;
        post.replyTo.replyType = replyToType;
        _posts.push(post);

        _postToday[MemeLibrary.getDay()].push(_postId);
        _postToday[MemeLibrary.getWeek()].push(_postId);
        _postToday[MemeLibrary.getMonth()].push(_postId);

        _postsByAuthor[msg.sender].push(_postId);

        uint256 currentId = _postId;

        _postId++;

        emit PostAdded(currentId, title);

        return currentId;
    }

    function editPost(string memory title, string memory content, uint256 postId, uint256 replyToId, ReplyToType replyToType) public {
        _verifyReply(replyToType, replyToId);

        Post storage post = _posts[_postIndex[postId]];
        require(post.author == msg.sender || owner() == msg.sender || hasRole(MOD_ROLE, msg.sender), "Wrong sender");
        require(post.id == postId, "Post does not exist");
        post.content = content;
        post.title = title;
        post.editTime = block.timestamp;
        post.replyTo.id = replyToId;
        post.replyTo.replyType = replyToType;
        emit PostEdited(postId, title);
    }

    function removePost(uint256 postId) public {
        uint256 index = _postIndex[postId];
        Post memory post = _posts[index];
        require(post.author == msg.sender || owner() == msg.sender || hasRole(MOD_ROLE, msg.sender), "Wrong sender");
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

        uint256[] memory authorIds = _postsByAuthor[post.author];
        uint256[] memory nextIds = new uint256[](authorIds.length - 1);
        uint256 nextIndex = 0;
        for (uint256 i = 0; i < authorIds.length; i++) {
            if (authorIds[i] != post.id) {
                nextIds[nextIndex] = authorIds[i];
                nextIndex++;
            }
        }
        _postsByAuthor[post.author] = nextIds;
        emit PostRemoved(postId, post.title, msg.sender);
    }

    function _getPosts(FilterType filter, SortType order, uint256 skip, uint256 limit, uint256[] memory tagHashes, address author) internal view returns(Post[] memory,uint256) {
        (Post[] memory posts,uint256 skipped) = filter == FilterType.LATEST ? _getNewestPosts(skip, limit, tagHashes, author) : _filterPostsBy(filter, skip, limit, tagHashes, author);
        return (MemeLibrary.mergeSortPosts(posts, order),skipped);
    }

    function getPosts(FilterType filter, SortType order, uint256 skip, uint256 limit, uint256[] calldata tagHashes, address author) public view returns(Post[] memory,uint256) {
        return _getPosts(filter, order, skip, limit, tagHashes, author);
    }

    function getPost(uint256 postId) public view returns(Post memory) {
        return _posts[_postIndex[postId]];
    }
}