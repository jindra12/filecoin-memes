// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MemePosts} from "../src/MemePosts.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {TestLibrary} from "./TestLibrary.sol";

contract MemePostsTest is Test,MemePosts {
    address[] public accounts;
    uint256 _accountCount = 10;

    function setUp() public {
        for (uint256 i = 0; i < _accountCount; i++) {
            (address acc,) = TestLibrary.makeAccount(vm, uint32(i), 50);
            accounts[i] = acc;
        }

        _grantRole(MOD_ROLE, accounts[0]);
        _grantRole(MOD_ROLE, accounts[1]);
        _grantRole(MOD_ROLE, accounts[2]);

        _likeFee = 50;
        _likeAdminProfit = 10;
        _likeFeeProfit = 10;

        Comment memory c;
        c.id = 1;
        _comments.push(c);
        _commentIndex[1] = 0;
    }

    function testAddPost() public {
        vm.prank(accounts[4]);
        _addPost("This", "This is a Post", 0, ReplyToType.NONE);
        vm.prank(accounts[5]);
        _addPost("This", "This is a POST too", 1, ReplyToType.POST);
        vm.prank(accounts[6]);
        _addPost("This", "This is a post three", 1, ReplyToType.COMMENT);

        assertEq(_postId, 4);
        assertEq(_postIndex[1], 0);
        assertEq(_postIndex[2], 1);
        assertEq(_postIndex[3], 2);
        assertEq(_posts.length, 3);
        assertEq(_posts[0].id, 1);
        assertEq(_posts[1].id, 2);
        assertEq(_posts[2].id, 3);
        Post memory p = _posts[2];
        assertEq(uint256(p.replyTo.replyType), uint256(ReplyToType.COMMENT));
        assertEq(p.replyTo.id, 1);
    }

    function testEditPost() public {
        vm.prank(accounts[5]);
        vm.expectRevert("Wrong sender");
        editPost("Nice", "Nice", 1, 1, ReplyToType.NONE);

        vm.prank(accounts[4]);
        editPost("Noice", "Nice", 1, 1, ReplyToType.POST);

        assertEq(_posts[0].title, "Nice");
        assertEq(uint256(_posts[0].replyTo.replyType), uint256(ReplyToType.POST));
    }

    function testRemovePost() public {
        vm.prank(accounts[5]);
        vm.expectRevert("Wrong sender");
        removePost(1);

        vm.prank(accounts[3]);
        removePost(1);

        vm.prank(owner());
        removePost(2);

        assertEq(_posts.length, 1);
        assertEq(_posts[0].id, 3);

        vm.prank(accounts[6]);
        removePost(3);

        assertEq(_posts.length, 0);
    }

    function testGetPost() public {
        vm.prank(accounts[6]);
        uint256 id = _addPost("This", "This is a comment three", 1, ReplyToType.COMMENT);

        Post memory p = getPost(id);
        assertEq(p.id, 4);
        assertEq(p.content, "This");
        vm.prank(owner());
        removePost(p.id);
    }

    function testGetNewestPosts() public {
        vm.warp(500);
        uint256 id1 = _addPost("One", "One", 1, ReplyToType.COMMENT);
        vm.warp(1000);
        uint256 id2 = _addPost("Two", "Two", 1, ReplyToType.COMMENT);
        vm.warp(750);
        uint256 id3 = _addPost("Three", "Three", 1, ReplyToType.COMMENT);
        vm.warp(2000);
        uint256 id4 = _addPost("Four", "Four", 1, ReplyToType.COMMENT);
        vm.warp(100);
        uint256 id5 = _addPost("Five", "Five", 1, ReplyToType.COMMENT);

        (Post[] memory posts,uint256 nextId) = _getNewestPosts(1, 3, new uint256[](0), address(0));

        assertEq(nextId, 3);

        assertEq(posts[0].title, "One");
        assertEq(posts[1].title, "Three");
        assertEq(posts[2].title, "Two");

        vm.prank(owner());
        removePost(id1);
        vm.prank(owner());
        removePost(id2);
        vm.prank(owner());
        removePost(id3);
        vm.prank(owner());
        removePost(id4);
        vm.prank(owner());
        removePost(id5);
    }

    function testFilterPostsBy() public {
        uint256 today = 60 days;
        vm.warp(today);
        uint256 id1 = _addPost("One", "One", 1, ReplyToType.COMMENT);
        vm.warp(today - 5 days);
        uint256 id2 = _addPost("One", "Two", 1, ReplyToType.COMMENT);
        vm.warp(today - 14 days);
        uint256 id3 = _addPost("One", "Three", 1, ReplyToType.COMMENT);
        vm.warp(today - 1 days);
        uint256 id4 = _addPost("One", "Four", 1, ReplyToType.COMMENT);
        vm.warp(today - 6 days);
        uint256 id5 = _addPost("One", "Five", 1, ReplyToType.COMMENT);
        vm.warp(today - 28 days);
        uint256 id6 = _addPost("One", "Six", 1, ReplyToType.COMMENT);
        vm.warp(today - 31 days);
        uint256 id7 = _addPost("One", "Seven", 1, ReplyToType.COMMENT);

        vm.warp(today);
        (Post[] memory posts1,uint256 nextId1) = _filterPostsBy(FilterType.DAY, 0, 2, new uint256[](0), address(0));
        (Post[] memory posts2,uint256 nextId2) = _filterPostsBy(FilterType.MONTH, 0, 3, new uint256[](0), address(0));
        (Post[] memory posts3,uint256 nextId3) = _filterPostsBy(FilterType.WEEK, 0, 10, new uint256[](0), address(0));

        assertEq(nextId1, 3);
        assertEq(nextId2, 4);
        assertEq(nextId3, 0);

        assertEq(posts1.length, 1);
        assertEq(posts1[0].title, "One");
        assertEq(posts2.length, 4);
        assertEq(posts2[0].title, "One");
        assertEq(posts2[1].title, "Two");
        assertEq(posts2[2].title, "Four");
        assertEq(posts3.length, 5);
        assertEq(posts3[0].title, "One");
        assertEq(posts3[1].title, "Two");
        assertEq(posts3[2].title, "Four");
        assertEq(posts3[3].title, "Five");
        assertEq(posts3[3].title, "Six");

        vm.prank(owner());
        removePost(id1);
        vm.prank(owner());
        removePost(id2);
        vm.prank(owner());
        removePost(id3);
        vm.prank(owner());
        removePost(id4);
        vm.prank(owner());
        removePost(id5);
        vm.prank(owner());
        removePost(id6);
        vm.prank(owner());
        removePost(id7);
    }

    function testGetPosts() public {
        uint256 today = 60 days;
        vm.warp(today);
        uint256 id1 = _addPost("One", "One", 1, ReplyToType.COMMENT);
        vm.warp(today - 5 days);
        uint256 id2 = _addPost("One", "Two", 1, ReplyToType.COMMENT);
        vm.warp(today - 14 days);
        uint256 id3 = _addPost("One", "Three", 1, ReplyToType.COMMENT);
        vm.warp(today - 1 days);
        uint256 id4 = _addPost("One", "Four", 1, ReplyToType.COMMENT);
        vm.warp(today - 6 days);
        uint256 id5 = _addPost("One", "Five", 1, ReplyToType.COMMENT);
        vm.warp(today - 28 days);
        uint256 id6 = _addPost("One", "Six", 1, ReplyToType.COMMENT);
        vm.warp(today - 31 days);
        uint256 id7 = _addPost("One", "Seven", 1, ReplyToType.COMMENT);

        getPost(id1).likes.likesCount = 100;
        getPost(id2).likes.likesCount = 9;
        getPost(id3).likes.likesCount = 80;
        getPost(id4).likes.likesCount = 7;
        getPost(id5).likes.likesCount = 60;
        getPost(id6).likes.likesCount = 5;
        getPost(id7).likes.likesCount = 40;

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

        (Post[] memory posts1,uint256 nextId1) = _getPosts(FilterType.WEEK, SortType.TIME, 2, 3, new uint256[](0), address(0));
        (Post[] memory posts2,uint256 nextId2) = _getPosts(FilterType.WEEK, SortType.LIKE, 2, 3, new uint256[](0), address(0));
        (Post[] memory posts3,uint256 nextId3) = _getPosts(FilterType.WEEK, SortType.HOT, 2, 3, new uint256[](0), address(0));

        assertEq(posts1.length, 3);
        assertEq(posts2.length, 3);
        assertEq(posts3.length, 3);

        assertEq(nextId1, 5);
        assertEq(nextId2, 5);
        assertEq(nextId3, 5);

        assertEq(posts1[0].content, "One");
        assertEq(posts1[1].content, "Four");
        assertEq(posts1[2].content, "Two");

        assertEq(posts2[0].content, "One");
        assertEq(posts2[1].content, "Five");
        assertEq(posts2[2].content, "Two");

        assertEq(posts3[0].content, "One");
        assertEq(posts3[1].content, "Five");
        assertEq(posts3[2].content, "Two");

        removePost(id1);
        removePost(id2);
        removePost(id3);
        removePost(id4);
        removePost(id5);
        removePost(id6);
        removePost(id7);
    }

    function testGetByTags() public {
        uint256 id1 = _addPost("One", "One", 0, ReplyToType.NONE);
        uint256 id2 = _addPost("Two", "Two", 0, ReplyToType.NONE);
        uint256 id3 = _addPost("Three", "Three", 0, ReplyToType.NONE);
        uint256[] memory tags = new uint256[](5);
        tags[0] = uint256(keccak256("Hello"));
        tags[1] = uint256(keccak256("World"));
        tags[2] = uint256(keccak256("This"));
        tags[3] = uint256(keccak256("Is"));
        tags[4] = uint256(keccak256("Patrick"));
        _postsByTag[tags[0]][id1] = true;
        _postsByTag[tags[1]][id1] = true;
        _postsByTag[tags[2]][id2] = true;
        _postsByTag[tags[3]][id2] = true;
        _postsByTag[tags[4]][id3] = true;

        uint256[] memory tags1 = new uint256[](1);
        tags1[0] = tags[0];
        (Post[] memory posts1, uint256 nextId1) = _getPosts(FilterType.LATEST, SortType.TIME, 0, 3, tags1, address(0));

        assertEq(nextId1, 0);
        assertEq(posts1.length, 1);
        assertEq(posts1[0].title, "One");

        uint256[] memory tags2 = new uint256[](2);
        tags1[0] = tags[3];
        tags1[1] = tags[4];
        (Post[] memory posts2, uint256 nextId2) = _getPosts(FilterType.LATEST, SortType.TIME, 0, 3, tags2, address(0));

        assertEq(nextId2, 0);
        assertEq(posts2.length, 2);
        assertEq(posts2[0].title, "Two");
        assertEq(posts2[1].title, "Three");

        removePost(id1);
        removePost(id2);
        removePost(id3);
    }

    function testGetByAuthor() public {
        vm.prank(accounts[5]);
        uint256 id1 = _addPost("One", "One", 0, ReplyToType.NONE);
        vm.prank(accounts[6]);
        uint256 id2 = _addPost("Two", "Two", 0, ReplyToType.NONE);
        vm.prank(accounts[6]);
        uint256 id3 = _addPost("Three", "Three", 0, ReplyToType.NONE);

        (Post[] memory posts1, uint256 nextId1) = _getPosts(FilterType.LATEST, SortType.TIME, 0, 3, new uint256[](0), accounts[5]);
        assertEq(nextId1, 0);
        assertEq(posts1[0].title, "One");

        (Post[] memory posts2, uint256 nextId2) = _getPosts(FilterType.LATEST, SortType.TIME, 0, 3, new uint256[](0), accounts[6]);
        assertEq(nextId2, 0);
        assertEq(posts2[0].title, "Two");
        assertEq(posts2[1].title, "Three");

        removePost(id1);
        removePost(id2);
        removePost(id3);
    }
}