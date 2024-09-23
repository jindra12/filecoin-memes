// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MemeComments} from "../src/MemeComments.sol";
import {MemeStructs} from "../src/MemeStructs.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {TestLibrary} from "./TestLibrary.sol";

contract MemeCommentsInternal is MemeComments {
    constructor(address[] memory accounts) {
        _postIndex[1] = 0;
        Post memory post;
        post.id = 1;
        post.author = accounts[4];
        _posts.push(post);

        _postIndex[2] = 1;
        Post memory post1;
        post1.id = 2;
        post1.author = accounts[5];
        _posts.push(post1);

        _grantRole(MOD_ROLE, accounts[0]);
        _grantRole(MOD_ROLE, accounts[1]);
        _grantRole(MOD_ROLE, accounts[2]);

        _likeFee = 50;
        _likeAdminProfit = 10;
        _likeFeeProfit = 10;
    }

    function commentId() public view returns(uint256) {
        return _commentId;
    }

    function commentsIndex(uint256 at) public view returns(uint256) {
        return _commentIndex[at];
    }

    function comments() public view returns(Comment[] memory) {
        return _comments;
    }

    function posts() public view returns(Post[] memory) {
        return _posts;
    }

    function getNewestComments(uint256 postId, uint256 skip, uint256 limit) public view returns(Comment[] memory,uint256) {
        return _getNewestComments(postId, skip, limit);
    }

    function filterCommentsBy(uint256 postId, FilterType kind, uint256 skip, uint256 limit) public view returns(Comment[] memory,uint256) {
        return _filterCommentsBy(postId, kind, skip, limit);
    }
}

contract MemeCommentsTest is Test,MemeStructs {
    address[] public accounts;
    MemeCommentsInternal memeComments;
    uint256 _accountCount = 10;

    function setUp() public {
        for (uint256 i = 0; i < _accountCount; i++) {
            (address acc,) = TestLibrary.makeAccount(vm, uint32(i), 50);
            accounts.push(acc);
        }

        memeComments = new MemeCommentsInternal(accounts);
    }

    function testAddComment() public {
        vm.prank(accounts[4]);
        memeComments.addComment("This is a comment", 1, 0, ReplyToType.NONE);
        vm.prank(accounts[5]);
        memeComments.addComment("This is a comment too", 1, 1, ReplyToType.POST);
        vm.prank(accounts[6]);
        memeComments.addComment("This is a comment three", 2, 1, ReplyToType.COMMENT);

        assertEq(memeComments.commentId(), 4);
        assertEq(memeComments.commentsIndex(1), 0);
        assertEq(memeComments.commentsIndex(2), 1);
        assertEq(memeComments.commentsIndex(3), 2);
        assertEq(memeComments.comments().length, 3);
        assertEq(memeComments.comments()[0].id, 1);
        assertEq(memeComments.comments()[1].id, 2);
        assertEq(memeComments.comments()[2].id, 3);
        Comment memory c = memeComments.comments()[2];
        assertEq(uint256(c.replyTo.replyType), uint256(ReplyToType.COMMENT));
        assertEq(c.replyTo.id, memeComments.comments()[0].id);
        Comment memory c1 = memeComments.comments()[1];
        assertEq(uint256(c1.replyTo.replyType), uint256(ReplyToType.POST));
        assertEq(c1.replyTo.id, memeComments.posts()[0].id);
        assertEq(uint256(memeComments.comments()[0].replyTo.replyType), uint256(ReplyToType.NONE));
    }

    function testEditComment() public {
        vm.prank(accounts[4]);
        memeComments.addComment("This is a comment", 1, 0, ReplyToType.NONE);
        vm.prank(accounts[5]);
        memeComments.addComment("This is a comment too", 1, 1, ReplyToType.POST);
        vm.prank(accounts[6]);
        memeComments.addComment("This is a comment three", 2, 1, ReplyToType.COMMENT);

        vm.prank(accounts[5]);
        vm.expectRevert("Wrong sender");
        memeComments.editComment("Nice", 1, 0, ReplyToType.NONE);

        vm.prank(accounts[4]);
        memeComments.editComment("Nice", 1, 1, ReplyToType.POST);

        assertEq(memeComments.comments()[0].content, "Nice");
        assertEq(uint256(memeComments.comments()[0].replyTo.replyType), uint256(ReplyToType.POST));
    }

    function testRemoveComment() public {
        vm.prank(accounts[4]);
        memeComments.addComment("This is a comment", 1, 0, ReplyToType.NONE);
        vm.prank(accounts[5]);
        memeComments.addComment("This is a comment too", 1, 1, ReplyToType.POST);
        vm.prank(accounts[6]);
        memeComments.addComment("This is a comment three", 2, 1, ReplyToType.COMMENT);

        vm.prank(accounts[5]);
        vm.expectRevert("Wrong sender");
        memeComments.removeComment(1);

        vm.prank(accounts[3]);
        memeComments.removeComment(1);

        vm.prank(memeComments.owner());
        memeComments.removeComment(2);

        assertEq(memeComments.comments().length, 1);
        assertEq(memeComments.comments()[0].id, 3);

        vm.prank(accounts[6]);
        memeComments.removeComment(3);

        assertEq(memeComments.comments().length, 0);
    }

    function testGetComment() public {
        vm.prank(accounts[6]);
        uint256 id = memeComments.addComment("This is a comment three", 2, 1, ReplyToType.COMMENT);

        Comment memory c = memeComments.getComment(id);
        assertEq(c.id, 4);
        assertEq(c.content, "This is a comment three");
        vm.prank(memeComments.owner());
        memeComments.removeComment(c.id);
    }

    function testGetNewestComments() public {
        vm.warp(500);
        uint256 id1 = memeComments.addComment("One", 2, 1, ReplyToType.COMMENT);
        vm.warp(1000);
        uint256 id2 = memeComments.addComment("Two", 2, 1, ReplyToType.COMMENT);
        vm.warp(750);
        uint256 id3 = memeComments.addComment("Three", 2, 1, ReplyToType.COMMENT);
        vm.warp(2000);
        uint256 id4 = memeComments.addComment("Four", 2, 1, ReplyToType.COMMENT);
        vm.warp(100);
        uint256 id5 = memeComments.addComment("Five", 2, 1, ReplyToType.COMMENT);

        (Comment[] memory comments,uint256 nextId) = memeComments.getNewestComments(2, 1, 3);

        assertEq(nextId, 3);

        assertEq(comments[0].content, "One");
        assertEq(comments[1].content, "Three");
        assertEq(comments[2].content, "Two");

        vm.prank(memeComments.owner());
        memeComments.removeComment(id1);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id2);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id3);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id4);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id5);
    }

    function testFilterCommentsBy() public {
        uint256 today = 60 days;
        vm.warp(today);
        uint256 id1 = memeComments.addComment("One", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 5 days);
        uint256 id2 = memeComments.addComment("Two", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 14 days);
        uint256 id3 = memeComments.addComment("Three", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 1 days);
        uint256 id4 = memeComments.addComment("Four", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 6 days);
        uint256 id5 = memeComments.addComment("Five", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 28 days);
        uint256 id6 = memeComments.addComment("Six", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 31 days);
        uint256 id7 = memeComments.addComment("Seven", 2, 1, ReplyToType.COMMENT);

        vm.warp(today);
        (Comment[] memory comments1,uint256 nextId1) = memeComments.filterCommentsBy(2, FilterType.DAY, 0, 2);
        (Comment[] memory comments2,uint256 nextId2) = memeComments.filterCommentsBy(2, FilterType.MONTH, 0, 3);
        (Comment[] memory comments3,uint256 nextId3) = memeComments.filterCommentsBy(2, FilterType.WEEK, 0, 10);

        assertEq(nextId1, 3);
        assertEq(nextId2, 4);
        assertEq(nextId3, 0);

        assertEq(comments1.length, 1);
        assertEq(comments1[0].content, "One");
        assertEq(comments2.length, 4);
        assertEq(comments2[0].content, "One");
        assertEq(comments2[1].content, "Two");
        assertEq(comments2[2].content, "Four");
        assertEq(comments3.length, 5);
        assertEq(comments3[0].content, "One");
        assertEq(comments3[1].content, "Two");
        assertEq(comments3[2].content, "Four");
        assertEq(comments3[3].content, "Five");
        assertEq(comments3[3].content, "Six");

        vm.prank(memeComments.owner());
        memeComments.removeComment(id1);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id2);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id3);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id4);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id5);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id6);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id7);
    }

    function testGetComments() public {
        uint256 today = 60 days;
        vm.warp(today);
        uint256 id1 = memeComments.addComment("One", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 5 days);
        uint256 id2 = memeComments.addComment("Two", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 14 days);
        uint256 id3 = memeComments.addComment("Three", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 1 days);
        uint256 id4 = memeComments.addComment("Four", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 6 days);
        uint256 id5 = memeComments.addComment("Five", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 28 days);
        uint256 id6 = memeComments.addComment("Six", 2, 1, ReplyToType.COMMENT);
        vm.warp(today - 31 days);
        uint256 id7 = memeComments.addComment("Seven", 2, 1, ReplyToType.COMMENT);

        memeComments.getComment(id1).likes.likesCount = 100;
        memeComments.getComment(id2).likes.likesCount = 9;
        memeComments.getComment(id3).likes.likesCount = 80;
        memeComments.getComment(id4).likes.likesCount = 7;
        memeComments.getComment(id5).likes.likesCount = 60;
        memeComments.getComment(id6).likes.likesCount = 5;
        memeComments.getComment(id7).likes.likesCount = 40;

        /**
            HOT ratio:
            100 * 60 days = 6000
            9 * 55 days = 495
            80 * 46 days = 3680
            7 * 59 days = 413
            60 * 54 days = 3240
            5 * 32 days = 160
            40 * 29 days = 1160
         */

        (Comment[] memory comments1,uint256 nextId1) = memeComments.getComments(2, FilterType.WEEK, SortType.TIME, 2, 3);
        (Comment[] memory comments2,uint256 nextId2) = memeComments.getComments(2, FilterType.WEEK, SortType.LIKE, 2, 3);
        (Comment[] memory comments3,uint256 nextId3) = memeComments.getComments(2, FilterType.WEEK, SortType.HOT, 2, 3);

        assertEq(comments1.length, 3);
        assertEq(comments2.length, 3);
        assertEq(comments3.length, 3);

        assertEq(nextId1, 5);
        assertEq(nextId2, 5);
        assertEq(nextId3, 5);

        assertEq(comments1[0].content, "One");
        assertEq(comments1[1].content, "Four");
        assertEq(comments1[2].content, "Two");

        assertEq(comments2[0].content, "One");
        assertEq(comments2[1].content, "Five");
        assertEq(comments2[2].content, "Two");

        assertEq(comments3[0].content, "One");
        assertEq(comments3[1].content, "Five");
        assertEq(comments3[2].content, "Two");

        vm.prank(memeComments.owner());
        memeComments.removeComment(id1);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id2);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id3);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id4);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id5);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id6);
        vm.prank(memeComments.owner());
        memeComments.removeComment(id7);
    }
}