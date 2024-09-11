// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MemeLikes} from "../src/MemeLikes.sol";
import {MemeEvents} from "../src/MemeEvents.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {TestLibrary} from "./TestLibrary.sol";

contract MemeLikesInternal is MemeLikes {
    constructor() {
        _postIndex[1] = 0;
        Post memory post;
        _posts.push(post);
        _commentIndex[1] = 0;
        Comment memory comment;
        _comments.push(comment);
        _likeFeeProfit = 10;
        _likeAdminProfit = 50;
        _likeFee = 70;
    }
    function addLike(uint256 postId) public {
        _addLike(postId);
    }
    function addLike(uint256 postId, uint256 commentId) public {
        _addLike(postId, commentId);
    }
}

contract MemeLikesTest is Test,MemeEvents {
    address[] public accounts;
    uint256 _accountCount = 10;
    MemeLikesInternal public memeLikes;

    function setUp() public {
        for (uint256 i = 0; i < _accountCount; i++) {
            (address acc,) = TestLibrary.makeAccount(vm, uint32(i), 50);
            accounts.push(acc);
        }
        vm.prank(accounts[9]);
        memeLikes = new MemeLikesInternal();
    }

    function testRemoveLike() public {
        vm.expectRevert("Not liked before");
        memeLikes.removeLike(1);
        memeLikes.addLike(1);
        vm.expectEmit(true, false, false, false, address(memeLikes));
        emit RemoveLike(1);
        memeLikes.removeLike(1);
        assertFalse(memeLikes.getLiked(1));
    }

    function testAddLike() public {
        vm.expectEmit(true, false, false, false, address(memeLikes));
        emit AddLike(1);
        memeLikes.addLike(1);
        vm.expectRevert("Liked already");
        memeLikes.addLike(1);
        assertTrue(memeLikes.getLiked(1));
    }

    function testRemoveCommentLike() public {
        vm.expectRevert("Not liked before");
        memeLikes.removeLike(1, 1);
        memeLikes.addLike(1, 1);
        vm.expectEmit(true, true, false, false, address(memeLikes));
        emit RemoveLikeComment(1, 1);
        memeLikes.removeLike(1, 1);
        assertFalse(memeLikes.getLikedComment(1, 1));
    }

    function testAddCommentLike() public {
        vm.expectEmit(true, true, false, false, address(memeLikes));
        emit AddLikeComment(1, 1);
        memeLikes.addLike(1, 1);
        vm.expectRevert("Liked already");
        memeLikes.addLike(1, 1);
        assertTrue(memeLikes.getLikedComment(1, 1));
    }

    function testLikeFee() public {
        vm.prank(memeLikes.owner());
        vm.expectRevert("Invalid fees for likes");
        memeLikes.setLikeFee(30);

        vm.prank(accounts[0]);
        vm.expectRevert("Ownable: caller is not the owner");
        memeLikes.setLikeFee(61);

        vm.prank(memeLikes.owner());
        memeLikes.setLikeFee(61);
        assertEq(memeLikes.getLikeFee(), 61);
    }

    function testAdminFee() public {
        vm.prank(memeLikes.owner());
        vm.expectRevert("Invalid fees for likes");
        memeLikes.setAdminFee(100);

        vm.prank(accounts[0]);
        vm.expectRevert("Ownable: caller is not the owner");
        memeLikes.setAdminFee(30);

        vm.prank(memeLikes.owner());
        memeLikes.setAdminFee(5);
        assertEq(memeLikes.getAdminFee(), 5);
    }

    function testOwnerFee() public {
        vm.prank(memeLikes.owner());
        vm.expectRevert("Invalid fees for likes");
        memeLikes.setLikeFeeProfit(100);

        vm.prank(accounts[0]);
        vm.expectRevert("Ownable: caller is not the owner");
        memeLikes.setLikeFeeProfit(30);

        vm.prank(memeLikes.owner());
        memeLikes.setLikeFeeProfit(5);
        assertEq(memeLikes.getLikeFeeProfit(), 5);
    }
}