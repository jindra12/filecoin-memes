// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";

interface MemePageStructs {
    struct Likes {
        uint256 likesCount;
        address[] likes;
    }
    
    struct Comment {
        uint256 id;
        address author;
        string content;
        uint256 time;
        uint256 editTime;
        Likes likes;
    }
    
    struct Post {
        uint256 id;
        address author;
        uint256 time;
        uint256 editTime;
        string title;
        string content;
        Likes likes;
        Comment[] comments;
        Tag[] tags;
    }

    struct Tag {
        string name;
        uint256 hash;
        uint256 popularity;
    }
}

interface MemePageEvents {
    event AddLike(uint256 indexed postId);
    event AddLikeComment(uint256 indexed postId, uint256 indexed commentId);
    event PostAdded(uint256 indexed postId, string indexed title);
    event PostEdited(uint256 indexed postId, string indexed title);
    event PostDeleted(uint256 indexed postId, string indexed title);
    event CommentAdded(uint256 indexed postId, string indexed title);
    event CommentEdited(uint256 indexed postId, string indexed title);
    event CommentDeleted(uint256 indexed postId, string indexed title);
    event TagAdded(string indexed name);
}

contract MemePage is Ownable,MemePageStructs,MemePageEvents {
    mapping(uint256 => mapping(address => bool)) internal _likesMap;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) internal _likesCommentsMap;
    mapping(uint256 => mapping(uint256 => uint256)) internal _commentsMap;
    mapping(uint256 => uint256) internal _postsMap;

    mapping(uint256 => uint256[]) internal _postToday;
    mapping(uint256 => uint256[]) internal _postWeek;
    mapping(uint256 => uint256[]) internal _postMonth;

    mapping(uint256 => mapping(uint256 => uint256[])) internal _commentToday;
    mapping(uint256 => mapping(uint256 => uint256[])) internal _commentWeek;
    mapping(uint256 => mapping(uint256 => uint256[])) internal _commentMonth;

    mapping(uint256 => mapping(uint256 => bool)) internal _postsByTag;
    mapping(uint256 => string) internal _tagNames;
    mapping(uint256 => uint256) internal _tagPopularities;

    Tag[] internal _bestTags;
    uint256 internal _bestTagsLimit;

    Post[] internal _posts;
    mapping(uint256 => uint256) _postIndex;

    uint256 internal _postId = 1;
    uint256 internal _commentId = 1;
    uint256 internal _likeFee = 0;
    uint256 internal _likeFeeProfit = 0;

    function _addTag(Tag memory tag) internal {
        _tagNames[tag.hash] = tag.name;
        _tagPopularities[tag.hash] += 1;
        tag.popularity = _tagPopularities[tag.hash];

        if (_bestTags.length < _bestTagsLimit) {
            _bestTags.push(tag);
        } else {
            uint256 smallestPop = _bestTags[0].popularity;
            for (uint256 i = 1; i < _bestTags.length; i++) {
                if (smallestPop > _bestTags[i].popularity) {
                    smallestPop = _bestTags[i].popularity;
                }
            }
            for (uint256 i = 0; i < _bestTags.length; i++) {
                if (_bestTags[i].popularity == smallestPop) {
                    _bestTags[i] = tag;
                    break;
                }
            }
        }
    }

    function _getDay() internal view returns(uint256) {
        return block.timestamp / 1 days;
    }

    function _getWeek() internal view returns(uint256) {
        return block.timestamp / 7 days;
    }

    function _getMonth() internal view returns(uint256) {
        return block.timestamp / 30 days;
    }

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

    function _comparePostsByTime(Post memory a, Post memory b) internal pure returns(bool) {
        return b.time >= a.time;
    }

    function _comparePostsByHot(Post memory a, Post memory b) internal pure returns(bool) {
        return (b.time * b.likes.likesCount) >= (a.time * a.likes.likesCount);
    }

    function _comparePostsByLike(Post memory a, Post memory b) internal pure returns(bool) {
        return b.likes.likesCount >= a.likes.likesCount;
    }

    function _comparePosts(Post memory a, Post memory b, uint256 kind) internal pure returns(bool) {
        if (kind == 1) {
            return _comparePostsByTime(a, b);
        } else if (kind == 2) {
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

    function _compareComments(Comment memory a, Comment memory b, uint256 kind) internal pure returns(bool) {
        if (kind == 1) {
            return _compareCommentsByTime(a, b);
        } else if (kind == 2) {
            return _compareCommentsByHot(a, b);
        } else {
            return _compareCommentsByLike(a, b);
        }
    }

    function _filterPostsBy(uint256 kind, uint256 limit) internal view returns (Post[] memory) {
        Post[] memory posts = new Post[](limit);
        uint256 resultIndex = 0;
        uint256 timeUnit = kind == 1 ? _getDay() : kind == 2 ? _getWeek() : _getMonth(); 
        uint256[] memory ids = kind == 1 ? _postToday[timeUnit] : kind == 2 ? _postWeek[timeUnit] : _postMonth[timeUnit];

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 index = _postIndex[ids[i]];
            posts[resultIndex] = _posts[index];
            resultIndex++;
            if (limit == resultIndex) {
                break;
            }
        }

        return posts;
    }

    function _filterCommentsBy(uint256 postId, uint256 kind, uint256 limit) internal view returns (Comment[] memory) {
        Comment[] memory comments;
        uint256 resultIndex = 0;
        uint256 timeUnit = kind == 1 ? _getDay() : kind == 2 ? _getWeek() : _getMonth(); 
        uint256[] memory ids = kind == 1 ? _commentToday[postId][timeUnit] : kind == 2 ? _commentWeek[postId][timeUnit] : _commentMonth[postId][timeUnit];

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 postIndex = _postIndex[postId];
            uint256 commentIndex = _commentsMap[postId][ids[i]];
            comments[resultIndex] = _posts[postIndex].comments[commentIndex];
            resultIndex++;
            if (resultIndex == limit) {
                break;
            }
        }
         
        return comments;
    }

    function _filterPostsByTags(Post[] memory posts, uint256 limit, uint256[] memory tagHashes, string[] memory tags) internal view returns (Post[] memory) {
        require(tagHashes.length == tags.length, "Invalid tags sent");
        Post[] memory result = new Post[](limit);
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < posts.length; i++) {
            for (uint256 j = 0; j < tagHashes.length; j++) {
                if (_postsByTag[tagHashes[j]][posts[i].id]) {
                    result[resultIndex] = posts[i];
                    resultIndex++;
                    if (resultIndex == limit) {
                        return result;
                    }
                }
            }
        }

        return result;
    }

    constructor(uint256 likeFee, uint256 likeFeeProfit, ENS ens, string memory name, bytes32 addressReverseNode) {
        require(likeFee > likeFeeProfit, "Invalid fees for likes");
        _likeFee = likeFee;
        _likeFeeProfit = likeFeeProfit;
        if (address(ens) != address(0)) {
            ReverseRegistrar reverseRegistrar = ReverseRegistrar(ens.owner(addressReverseNode));
            reverseRegistrar.claim(address(this));
            reverseRegistrar.setName(name);
        }
    }

    function addLike(uint256 postId) public payable {
        require(!_likesMap[postId][msg.sender], "Liked already");
        Post storage post = _posts[_postIndex[postId]];
        like.likes.push(msg.sender);
        _likesMap[postId][msg.sender] = true;
        like.likesCount++;

        Post memory post = _posts[_postIndex[postId]];
        for (uint256 i = 0; i < post.tags.length; i++) {
            _addTag(post.tags[i]);
        }
    }

    function addLike(uint256 postId, uint256 commentId) public payable {
        require(!_likesCommentsMap[postId][commentId][msg.sender], "Liked already");
        Post storage post = _posts[_postIndex[postId]];
        Comment storage comment = post.comments[_commentsMap[postId][commentId]];
        like.likes.push(msg.sender);
        _likesCommentsMap[postId][commentId][msg.sender] = true;
        like.likesCount++;
    }

    function removeLike(uint256 postId) public {
        Post storage post = _posts[_postIndex[postId]];
        require(_likesMap[postId][msg.sender], "Not liked before");
        _likesMap[postId][msg.sender] = false;
        _removeLike(post.likes);
    }

    function removeLike(uint256 postId, uint256 commentId) public {
        Post storage post = _posts[_postIndex[postId]];
        Comment storage comment = post.comments[_commentsMap[postId][commentId]];
        require(_likesCommentsMap[postId][commentId][msg.sender], "Not liked before");
        _likesCommentsMap[postId][commentId][msg.sender] = false;
        _removeLike(comment.likes);
    }

    function addPost(string memory title, string memory content, uint256[] memory tagHashes, string[] memory tags) public {
        require(tagHashes.length == tags.length, "Invalid tags sent");
        uint256 postId = _postId;
        _postIndex[_postId] = _posts.length;
        Post memory post;
        post.id = postId;
        post.author = msg.sender;
        post.time = block.timestamp;
        post.title = title;
        post.content = content;
        _posts.push(post);

        _postToday[_getDay()].push(_postId);
        _postToday[_getWeek()].push(_postId);
        _postToday[_getMonth()].push(_postId);

        for (uint256 i = 0; i < tagHashes.length; i++) {
            Tag memory tag;
            tag.name = tags[i];
            tag.hash = tagHashes[i];
            _addTag(tag);
            _postsByTag[tag.hash][postId] = true;
            post.tags.push(tag);
        }

        _postId++;
    }

    function editPost(string memory title, string memory content, uint256 postId) public {
        Post storage post = _posts[_postIndex[postId]];
        require(post.author == msg.sender || owner() == msg.sender, "Wrong sender");
        require(post.id == postId, "Post does not exist");
        post.content = content;
        post.title = title;
        post.editTime = block.timestamp;
    }

    function removePost(uint256 postId) public {
        uint256 index = _postIndex[postId];
        Post memory post = _posts[index];
        require(post.author == msg.sender || owner() == msg.sender);
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

    function addComment(string memory content, uint256 postId) public {
        Post storage post = _posts[_postIndex[postId]];
        Comment memory comment;
        comment.id = _commentId;
        comment.author = msg.sender;
        comment.time = block.timestamp;
        comment.content = content;
        _commentsMap[postId][_commentId] = post.comments.length;
        post.comments.push(comment);

        _commentToday[_getDay()][postId].push(_commentId);
        _commentToday[_getWeek()][postId].push(_commentId);
        _commentToday[_getMonth()][postId].push(_commentId);

        _commentId++;
    }

    function editComment(string memory content, uint256 postId, uint256 commentId) public {
        uint256 index = _commentsMap[postId][commentId];
        Comment storage comment = _posts[_postIndex[postId]].comments[index];
        require(comment.author == msg.sender || owner() == msg.sender, "Wrong sender");
        require(comment.id == commentId, "Comment does not exist");
        comment.editTime = block.timestamp;
        comment.content = content;
    }

    function removeComment(uint256 postId, uint256 commentId) public {
        uint256 postIndex = _postIndex[postId];
        uint256 index = _commentsMap[postId][commentId];
        Comment memory comment = _posts[postIndex].comments[index];
        require(comment.author == msg.sender || owner() == msg.sender, "Wrong sender");
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
}