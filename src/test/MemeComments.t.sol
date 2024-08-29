// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MemeComments} from "../src/MemeComments.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {TestLibrary} from "./TestLibrary.sol";

contract MemeCommentsTest is Test,MemeComments {
    address[] public accounts;
    uint256 _accountCount = 10;

    function setUp() public {
        for (uint256 i = 0; i < _accountCount; i++) {
            (address acc,) = TestLibrary.makeAccount(vm, uint32(i), 50);
            accounts[i] = acc;
        }
        _postIndex[1] = 0;
        Post memory post;
        post.author = accounts[4];
        _posts[0] = post;

        _postIndex[2] = 1;
        Post memory post1;
        post1.author = accounts[5];
        _posts[1] = post1;

        _grantRole(MOD_ROLE, accounts[0]);
        _grantRole(MOD_ROLE, accounts[1]);
        _grantRole(MOD_ROLE, accounts[2]);

        _likeFee = 50;
        _likeAdminProfit = 10;
        _likeFeeProfit = 10;
    }

    function testAddComment() public {
        vm.prank(accounts[4]);
        addComment("This is a comment", 1, 0, ReplyToType.NONE);
        vm.prank(accounts[5]);
        addComment("This is a comment too", 1, 1, ReplyToType.POST);
        vm.prank(accounts[6]);
        addComment("This is a comment three", 2, 1, ReplyToType.COMMENT);

        assertEq(_commentId, 4);
        assertEq(_commentIndex[1], 0);
        assertEq(_commentIndex[2], 0);
        assertEq(_commentIndex[3], 0);
        assertEq(_comments.length, 3);
        assertEq(_comments[0].id, 1);
        assertEq(_comments[1].id, 2);
        assertEq(_comments[2].id, 3);
        Comment memory c = _comments[2];
        assertEq(uint256(c.replyTo.replyType), uint256(ReplyToType.COMMENT));
        assertEq(c.replyTo.id, _comments[0].id);
        Comment memory c1 = _comments[1];
        assertEq(uint256(c1.replyTo.replyType), uint256(ReplyToType.POST));
        assertEq(c1.replyTo.id, _posts[0].id);
        assertEq(uint256(_comments[0].replyTo.replyType), 0);
    }

    function testEditComment() public {
        vm.prank(accounts[5]);
        vm.expectRevert("Wrong sender");
        editComment("Nice", 1, 0, ReplyToType.NONE);

        vm.prank(accounts[4]);
        editComment("Nice", 1, 1, ReplyToType.POST);

        assertEq(bytes(_comments[0].content), bytes("Nice"));
        assertEq(uint256(_comments[0].replyTo.replyType), uint256(ReplyToType.POST));
    }

    function testRemoveComment() public {
        vm.prank(accounts[5]);
        vm.expectRevert("Wrong sender");
        removeComment(1);

        vm.prank(accounts[3]);
        removeComment(1);

        vm.prank(owner());
        removeComment(2);

        assertEq(_comments.length, 1);
        assertEq(_comments[0].id, 3);

        vm.prank(accounts[6]);
        removeComment(3);

        assertEq(_comments.length, 0);
    }

    function testGetComment() public {
        vm.prank(accounts[6]);
        uint256 id = addComment("This is a comment three", 2, 1, ReplyToType.COMMENT);

        Comment memory c = getComment(id);
        
    }

    function testGetNewestComments() public {

    }

    function testFilterCommentsBy() public {

    }

    function testGetComments() public {

    }
}