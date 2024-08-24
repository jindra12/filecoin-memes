// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {MemeStructs} from "./MemeStructs.sol";

library MemeLibrary {
    function getDay() internal view returns(uint256) {
        return block.timestamp / 1 days;
    }

    function getWeek() internal view returns(uint256) {
        return block.timestamp / 7 days;
    }

    function getMonth() internal view returns(uint256) {
        return block.timestamp / 30 days;
    }

    function comparePostsByTime(MemeStructs.Post memory a, MemeStructs.Post memory b) internal pure returns(bool) {
        return b.time >= a.time;
    }

    function multiplyProtectOverflow(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 result = a * b;
        if (result / b != a) {
            return type(uint256).max;
        }
        return result;
    }

    function comparePostsByHot(MemeStructs.Post memory a, MemeStructs.Post memory b) internal pure returns(bool) {
        return multiplyProtectOverflow(b.time, b.likes.likesCount) >= multiplyProtectOverflow(a.time, a.likes.likesCount);
    }

    function comparePostsByLike(MemeStructs.Post memory a, MemeStructs.Post memory b) internal pure returns(bool) {
        return b.likes.likesCount >= a.likes.likesCount;
    }

    function comparePosts(MemeStructs.Post memory a, MemeStructs.Post memory b, MemeStructs.SortType kind) internal pure returns(bool) {
        if (kind == MemeStructs.SortType.TIME) {
            return comparePostsByTime(a, b);
        } else if (kind == MemeStructs.SortType.HOT) {
            return comparePostsByHot(a, b);
        } else {
            return comparePostsByLike(a, b);
        }
    }

    function addSortedPosts(MemeStructs.Post[] memory aS, MemeStructs.Post[] memory bS, MemeStructs.SortType kind) internal pure returns(MemeStructs.Post[] memory) {
        uint256 asIndex = 0;
        uint256 bsIndex = 0;
        MemeStructs.Post[] memory result = new MemeStructs.Post[](aS.length + bS.length);
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
            } else if (comparePosts(aS[asIndex], bS[bsIndex], kind)) {
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

    function slicePosts(MemeStructs.Post[] memory posts, uint256 from, uint256 to) internal pure returns(MemeStructs.Post[] memory) {
        MemeStructs.Post[] memory sliced = new MemeStructs.Post[](to - from);
        uint256 slicedIndex = 0;
        for (uint256 i = from; i < to; i++) {
            sliced[slicedIndex] = posts[i];
            slicedIndex++;
        }
        return sliced;
    }

    function mergeSortPosts(MemeStructs.Post[] memory posts, MemeStructs.SortType kind) internal pure returns(MemeStructs.Post[] memory) {
        if (posts.length == 1) {
            return posts;
        }
        uint256 halfIndex = posts.length / 2;
        MemeStructs.Post[] memory first = slicePosts(posts, 0, halfIndex);
        MemeStructs.Post[] memory second = slicePosts(posts, halfIndex, posts.length);

        return addSortedPosts(mergeSortPosts(first, kind), mergeSortPosts(second, kind), kind);
    }

    function addSortedComments(MemeStructs.Comment[] memory aS, MemeStructs.Comment[] memory bS, MemeStructs.SortType kind) internal pure returns(MemeStructs.Comment[] memory) {
        uint256 asIndex = 0;
        uint256 bsIndex = 0;
        MemeStructs.Comment[] memory result = new MemeStructs.Comment[](aS.length + bS.length);
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
            } else if (compareComments(aS[asIndex], bS[bsIndex], kind)) {
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

    function sliceComments(MemeStructs.Comment[] memory comments, uint256 from, uint256 to) internal pure returns(MemeStructs.Comment[] memory) {
        MemeStructs.Comment[] memory sliced = new MemeStructs.Comment[](to - from);
        uint256 slicedIndex = 0;
        for (uint256 i = from; i < to; i++) {
            sliced[slicedIndex] = comments[i];
            slicedIndex++;
        }
        return sliced;
    }

    function mergeSortComments(MemeStructs.Comment[] memory comments, MemeStructs.SortType kind) internal pure returns(MemeStructs.Comment[] memory) {
        if (comments.length == 1) {
            return comments;
        }
        uint256 halfIndex = comments.length / 2;
        MemeStructs.Comment[] memory first = sliceComments(comments, 0, halfIndex);
        MemeStructs.Comment[] memory second = sliceComments(comments, halfIndex, comments.length);

        return addSortedComments(mergeSortComments(first, kind), mergeSortComments(second, kind), kind);
    }

    function compareCommentsByTime(MemeStructs.Comment memory a, MemeStructs.Comment memory b) internal pure returns(bool) {
        return b.time >= a.time;
    }

    function compareCommentsByHot(MemeStructs.Comment memory a, MemeStructs.Comment memory b) internal pure returns(bool) {
        return (b.time * b.likes.likesCount) >= (a.time * a.likes.likesCount);
    }

    function compareCommentsByLike(MemeStructs.Comment memory a, MemeStructs.Comment memory b) internal pure returns(bool) {
        return b.likes.likesCount >= a.likes.likesCount;
    }

    function compareComments(MemeStructs.Comment memory a, MemeStructs.Comment memory b, MemeStructs.SortType kind) internal pure returns(bool) {
        if (kind == MemeStructs.SortType.TIME) {
            return compareCommentsByTime(a, b);
        } else if (kind == MemeStructs.SortType.HOT) {
            return compareCommentsByHot(a, b);
        } else {
            return compareCommentsByLike(a, b);
        }
    }

    function filterPostByAuthor(MemeStructs.Post memory post, address author) internal pure returns(bool) {
        return author == address(0) || post.author == author;
    }
}