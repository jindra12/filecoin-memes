// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MemeStructs} from "../src/MemeStructs.sol";
import {MemeLibrary} from "../src/MemeLibrary.sol";
import {TestLibrary} from "./TestLibrary.sol";

contract MemeLibraryTest is Test {
    MemeStructs.Post[] public posts;
    MemeStructs.Comment[] public comments;

    function setUp() public {
        delete posts;
        delete comments;
    }

    function testGetDay() public {
        vm.warp(5 days);
        assertEq(MemeLibrary.getDay(), 5);
        vm.warp(8 days);
        assertEq(MemeLibrary.getDay(), 8);
    }
    function testGetWeek() public {
        vm.warp(21 days);
        assertEq(MemeLibrary.getWeek(), 3);
        vm.warp(42 days);
        assertEq(MemeLibrary.getWeek(), 6);
    }
    function testGetMonth() public {
        vm.warp(120 days);
        assertEq(MemeLibrary.getMonth(), 4);
        vm.warp(150 days);
        assertEq(MemeLibrary.getMonth(), 5);
    }
    function testComparePostsByTime() public {
        TestLibrary.populatePosts(vm, posts, 2);
        assertGt(posts[1].time, posts[0].time);
        assertFalse(MemeLibrary.comparePostsByTime(posts[0], posts[1]));
        assertTrue(MemeLibrary.comparePostsByTime(posts[1], posts[0]));
    }
    function testComparePostsByHot() public {
        TestLibrary.populatePosts(vm, posts, 2);
        assertGt(posts[1].time, posts[0].time);
        assertGt(posts[1].likes.likesCount, posts[0].likes.likesCount);
        assertFalse(MemeLibrary.comparePostsByHot(posts[0], posts[1]));
        assertTrue(MemeLibrary.comparePostsByHot(posts[1], posts[0]));
    }
    function testComparePostsByLike() public {
        TestLibrary.populatePosts(vm, posts, 2);
        assertGt(posts[1].likes.likesCount, posts[0].likes.likesCount);
        assertFalse(MemeLibrary.comparePostsByLike(posts[0], posts[1]));
        assertTrue(MemeLibrary.comparePostsByLike(posts[1], posts[0]));
    }
    function testComparePosts() public {
        TestLibrary.populatePosts(vm, posts, 2);
        assertFalse(MemeLibrary.comparePosts(posts[0], posts[1], MemeStructs.SortType.TIME));
        assertTrue(MemeLibrary.comparePosts(posts[1], posts[0], MemeStructs.SortType.TIME));
        assertFalse(MemeLibrary.comparePosts(posts[0], posts[1], MemeStructs.SortType.HOT));
        assertTrue(MemeLibrary.comparePosts(posts[1], posts[0], MemeStructs.SortType.HOT));
        assertFalse(MemeLibrary.comparePosts(posts[0], posts[1], MemeStructs.SortType.LIKE));
        assertTrue(MemeLibrary.comparePosts(posts[1], posts[0], MemeStructs.SortType.LIKE));
    }
    function testAddSortedPosts() public pure {
        MemeStructs.Post[] memory aS = new MemeStructs.Post[](3);
        MemeStructs.Post[] memory bS = new MemeStructs.Post[](4);
        
        aS[2].time = 1;
        aS[1].time = 20;
        aS[0].time = 40;

        bS[3].time = 2;
        bS[2].time = 33;
        bS[1].time = 150;
        bS[0].time = 151;

        MemeStructs.Post[] memory added = MemeLibrary.addSortedPosts(aS, bS, MemeStructs.SortType.TIME);
        assertEq(added.length, 7);
        assertEq(added[6].time, 1);
        assertEq(added[5].time, 2);
        assertEq(added[4].time, 20);
        assertEq(added[3].time, 33);
        assertEq(added[2].time, 40);
        assertEq(added[1].time, 150);
        assertEq(added[0].time, 151);
    }
    function testSlicePosts() public pure {
        MemeStructs.Post[] memory aS = new MemeStructs.Post[](6);
        MemeStructs.Post[] memory slice1 = MemeLibrary.slicePosts(aS, 0, 3);
        assertEq(slice1.length, 3);
        MemeStructs.Post[] memory slice2 = MemeLibrary.slicePosts(aS, 3, 6);
        assertEq(slice2.length, 3);
    }
    function testMergeSortPosts() public {
        TestLibrary.populatePosts(vm, posts, 11);
        MemeStructs.Post[] memory sorted = MemeLibrary.mergeSortPosts(posts, MemeStructs.SortType.TIME);
        assertEq(sorted.length, 11);
        for (uint256 i = 1; i < sorted.length; i++) {
            assertGe(sorted[i - 1].time, sorted[i].time);
        }
    }
    function testCompareCommentsByTime() public {
        TestLibrary.populateComments(vm, comments, 2);
        assertFalse(MemeLibrary.compareCommentsByTime(comments[0], comments[1]));
        assertTrue(MemeLibrary.compareCommentsByTime(comments[1], comments[0]));
    }
    function testCompareCommentsByHot() public {
        TestLibrary.populateComments(vm, comments, 2);
        assertFalse(MemeLibrary.compareCommentsByHot(comments[0], comments[1]));
        assertTrue(MemeLibrary.compareCommentsByHot(comments[1], comments[0]));
    }
    function testCompareCommentsByLike() public {
        TestLibrary.populateComments(vm, comments, 2);
        assertFalse(MemeLibrary.compareCommentsByLike(comments[0], comments[1]));
        assertTrue(MemeLibrary.compareCommentsByLike(comments[1], comments[0]));
    }
    function testCompareComments() public {
        TestLibrary.populateComments(vm, comments, 2);
        assertFalse(MemeLibrary.compareComments(comments[0], comments[1], MemeStructs.SortType.TIME));
        assertTrue(MemeLibrary.compareComments(comments[1], comments[0], MemeStructs.SortType.TIME));
        assertFalse(MemeLibrary.compareComments(comments[0], comments[1], MemeStructs.SortType.HOT));
        assertTrue(MemeLibrary.compareComments(comments[1], comments[0], MemeStructs.SortType.HOT));
        assertFalse(MemeLibrary.compareComments(comments[0], comments[1], MemeStructs.SortType.LIKE));
        assertTrue(MemeLibrary.compareComments(comments[1], comments[0], MemeStructs.SortType.LIKE));
    }
    function testAddSortedComments() public pure {
        MemeStructs.Comment[] memory aS = new MemeStructs.Comment[](3);
        MemeStructs.Comment[] memory bS = new MemeStructs.Comment[](4);

        aS[2].time = 1;
        aS[1].time = 20;
        aS[0].time = 40;

        bS[3].time = 2;
        bS[2].time = 33;
        bS[1].time = 150;
        bS[0].time = 151;

        MemeStructs.Comment[] memory added = MemeLibrary.addSortedComments(aS, bS, MemeStructs.SortType.TIME);
        assertEq(added.length, 7);
        assertEq(added[6].time, 1);
        assertEq(added[5].time, 2);
        assertEq(added[4].time, 20);
        assertEq(added[3].time, 33);
        assertEq(added[2].time, 40);
        assertEq(added[1].time, 150);
        assertEq(added[0].time, 151);
    }
    function testSliceComments() public pure {
        MemeStructs.Comment[] memory aS = new MemeStructs.Comment[](6);
        MemeStructs.Comment[] memory slice1 = MemeLibrary.sliceComments(aS, 0, 3);
        assertEq(slice1.length, 3);
        MemeStructs.Comment[] memory slice2 = MemeLibrary.sliceComments(aS, 3, 6);
        assertEq(slice2.length, 3);
    }
    function testMergeSortComments() public {
        TestLibrary.populateComments(vm, comments, 11);
        MemeStructs.Comment[] memory sorted = MemeLibrary.mergeSortComments(comments, MemeStructs.SortType.TIME);
        assertEq(sorted.length, 11);
        for (uint256 i = 1; i < sorted.length; i++) {
            assertGe(sorted[i - 1].time, sorted[i].time);
        }
    }
    function testFilterPostByAuthor() public {
        TestLibrary.populatePosts(vm, posts, 11);
        address someAuthor = posts[5].author;
        assertTrue(MemeLibrary.filterPostByAuthor(posts[5], address(0)));
        assertTrue(MemeLibrary.filterPostByAuthor(posts[5], someAuthor));
        assertFalse(MemeLibrary.filterPostByAuthor(posts[4], someAuthor));
    }
}