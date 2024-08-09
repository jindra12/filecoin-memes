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
        uint256[] commentIds;
        uint256[] tagIds;
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
    mapping(uint256 => uint256) internal _postsMap;

    mapping(uint256 => uint256[]) internal _postToday;
    mapping(uint256 => uint256[]) internal _postWeek;
    mapping(uint256 => uint256[]) internal _postMonth;

    mapping(address => uint256[]) internal _postsByAuthor;

    mapping(uint256 => mapping(uint256 => uint256[])) internal _commentToday;
    mapping(uint256 => mapping(uint256 => uint256[])) internal _commentWeek;
    mapping(uint256 => mapping(uint256 => uint256[])) internal _commentMonth;

    mapping(uint256 => mapping(uint256 => bool)) internal _postsByTag;
    mapping(uint256 => string) internal _tagNames;
    mapping(uint256 => uint256) internal _tagPopularities;

    uint256 internal _ownerFees = 0;
    mapping(address => uint256) internal _authorsFees;

    Tag[] internal _bestTags;
    uint256 internal _bestTagsLimit;

    Post[] internal _posts;
    mapping(uint256 => uint256) _postIndex;

    Comment[] internal _comments;
    mapping(uint256 => uint256) _commentIndex;

    uint256 internal _postId = 1;
    uint256 internal _commentId = 1;
    uint256 internal _likeFee = 0;
    uint256 internal _likeFeeProfit = 0;

    uint256 internal _giveUpLimit = 5000;

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

    function _addSortedPosts(Post[] memory aS, Post[] memory bS, uint256 kind) internal pure returns(Post[] memory) {
        uint256 asIndex = 0;
        uint256 bsIndex = 0;
        Post[] memory result = new Post[](aS.length + bS.length);
        uint256 resultIndex = 0;

        while(resultIndex < (aS.length + bS.length)) {
            if (asIndex == aS.length) {
                result[resultIndex] = bS[bsIndex];
                resultIndex++;
                bsIndex++;
            } else if (bsIndex == bS.length) {
                result[resultIndex] = aS[asIndex];
                resultIndex++;
                asIndex++;
            } else if (_comparePosts(aS[asIndex], bS[bsIndex], kind)) {
                result[resultIndex] = bS[bsIndex];
                resultIndex++;
                bsIndex++;
            } else {
                result[resultIndex] = aS[asIndex];
                resultIndex++;
                asIndex++;
            }
        }

        return result;
    }

    function _slicePosts(Post[] memory posts, uint256 from, uint256 to) internal pure returns(Post[] memory) {
        Post[] memory sliced = new Post[](to - from);
        uint256 slicedIndex = 0;
        for (uint256 i = from; i < to; i++) {
            sliced[slicedIndex] = posts[i];
            slicedIndex++;
        }
        return sliced;
    }

    function _mergeSortPosts(Post[] memory posts, uint256 kind) internal pure returns(Post[] memory) {
        if (posts.length == 1) {
            return posts;
        }
        uint256 halfIndex = posts.length / 2;
        Post[] memory first = _slicePosts(posts, 0, halfIndex);
        Post[] memory second = _slicePosts(posts, halfIndex, posts.length);

        return _addSortedPosts(_mergeSortPosts(first, kind), _mergeSortPosts(second, kind), kind);
    }

    function _addSortedComments(Comment[] memory aS, Comment[] memory bS, uint256 kind) internal pure returns(Comment[] memory) {
        uint256 asIndex = 0;
        uint256 bsIndex = 0;
        Comment[] memory result = new Comment[](aS.length + bS.length);
        uint256 resultIndex = 0;

        while(resultIndex < (aS.length + bS.length)) {
            if (asIndex == aS.length) {
                result[resultIndex] = bS[bsIndex];
                resultIndex++;
                bsIndex++;
            } else if (bsIndex == bS.length) {
                result[resultIndex] = aS[asIndex];
                resultIndex++;
                asIndex++;
            } else if (_compareComments(aS[asIndex], bS[bsIndex], kind)) {
                result[resultIndex] = bS[bsIndex];
                resultIndex++;
                bsIndex++;
            } else {
                result[resultIndex] = aS[asIndex];
                resultIndex++;
                asIndex++;
            }
        }

        return result;
    }

    function _sliceComments(Comment[] memory comments, uint256 from, uint256 to) internal pure returns(Comment[] memory) {
        Comment[] memory sliced = new Comment[](to - from);
        uint256 slicedIndex = 0;
        for (uint256 i = from; i < to; i++) {
            sliced[slicedIndex] = comments[i];
            slicedIndex++;
        }
        return sliced;
    }

    function _mergeSortComments(Comment[] memory comments, uint256 kind) internal pure returns(Comment[] memory) {
        if (comments.length == 1) {
            return comments;
        }
        uint256 halfIndex = comments.length / 2;
        Comment[] memory first = _sliceComments(comments, 0, halfIndex);
        Comment[] memory second = _sliceComments(comments, halfIndex, comments.length);

        return _addSortedComments(_mergeSortComments(first, kind), _mergeSortComments(second, kind), kind);
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
            if (_filterPostByTags(viablePosts[i], tagHashes) && _filterPostByAuthor(viablePosts[i], author)) {
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

    function _filterPostsBy(uint256 kind, uint256 skip, uint256 limit, uint256[] memory tagHashes, address author) internal view returns (Post[] memory,uint256) {
        Post[] memory posts = new Post[](limit);
        uint256 resultIndex = 0;
        uint256 timeUnit = kind == 1 ? _getDay() : kind == 2 ? _getWeek() : _getMonth(); 
        uint256[] memory ids = kind == 1 ? _postToday[timeUnit] : kind == 2 ? _postWeek[timeUnit] : _postMonth[timeUnit];
        uint256 start = ids.length - 1;
        uint256 giveUpCount = 0;
        if (skip >= start) {
            return (posts,0);
        }
        for (uint256 i = start - skip; i >= 0; i--) {
            uint256 index = _postIndex[ids[i]];
            if (_filterPostByTags(_posts[index], tagHashes) && _filterPostByAuthor(_posts[index], author)) {
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
        uint256 timeUnit = kind == 1 ? _getDay() : kind == 2 ? _getWeek() : _getMonth(); 
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

    function _filterPostByAuthor(Post memory post, address author) internal pure returns(bool) {
        return author == address(0) || post.author == author;
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

        _authorsFees[comment.author] += _likeFee - _likeFeeProfit;
        _ownerFees += _likeFeeProfit;
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
            _posts[_posts.length - 1].tagIds.push(tag.hash);
        }

        _postsByAuthor[msg.sender].push(_postId);

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
    }

    function addComment(string memory content, uint256 postId) public {
        Comment memory comment;
        comment.id = _commentId;
        comment.author = msg.sender;
        comment.time = block.timestamp;
        comment.content = content;

        _commentIndex[_commentId] = _comments.length;
        _comments.push(comment);

        _commentToday[_getDay()][postId].push(_commentId);
        _commentToday[_getWeek()][postId].push(_commentId);
        _commentToday[_getMonth()][postId].push(_commentId);

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

    function getLikeFee() public view returns(uint256) {
        return _likeFee;
    }

    function getLikeFeeProfit() public view returns(uint256) {
        return _likeFeeProfit;
    }

    function setLikeFee(uint256 fee) public onlyOwner() {
        require(fee > _likeFeeProfit, "Invalid fees for likes");
        _likeFee = fee;
    }

    function setLikeFeeProfit(uint256 fee) public onlyOwner() {
        require(_likeFee > fee, "Invalid fees for likes");
        _likeFeeProfit = fee;
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

    function getWithdrawableOwner() public view returns(uint256) {
        return _ownerFees;
    }

    function getWithdrawableAuthor() public view returns(uint256) {
        return _authorsFees[msg.sender];
    }

    function getPosts(uint256 filter, uint256 order, uint256 skip, uint256 limit, uint256[] calldata tagHashes, address author) public view returns(Post[] memory,uint256) {
        (Post[] memory posts,uint256 skipped) = filter == 0 ? _getNewestPosts(skip, limit, tagHashes, author) : _filterPostsBy(filter, skip, limit, tagHashes, author);
        return (_mergeSortPosts(posts, order),skipped);
    }

    function getPost(uint256 postId) public view returns(Post memory) {
        return _posts[_postIndex[postId]];
    }

    function getComments(uint256 postId, uint256 filter, uint256 order, uint256 skip, uint256 limit) public view returns(Comment[] memory,uint256) {
        (Comment[] memory comments,uint256 skipped) = filter == 0 ? _getNewestComments(postId, skip, limit) : _filterCommentsBy(postId, filter, skip, limit);
        return (_mergeSortComments(comments, order),skipped);
    }

    function getComment(uint256 commentId) public view returns(Comment memory) {
        return _comments[_commentIndex[commentId]];
    }
}