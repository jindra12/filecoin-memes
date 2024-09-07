// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MemeLikes} from "../src/MemeLikes.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {TestLibrary} from "./TestLibrary.sol";

contract MemeLikesTest is Test,MemeLikes {
    address[] public accounts;
    uint256 _accountCount = 10;

    function setUp() public {
        for (uint256 i = 0; i < _accountCount; i++) {
            (address acc,) = TestLibrary.makeAccount(vm, uint32(i), 50);
            accounts.push(acc);
        }
        _postIndex[1] = 0;
        Post memory post;
        _posts[0] = post;
        _commentIndex[1] = 0;
        Comment memory comment;
        _comments[0] = comment;
    }

    function testRemoveLike() public {
        vm.expectRevert("Not liked before");
        removeLike(1);
        _likesMap[1][msg.sender] = true;
        vm.expectEmit(true, false, false, false, address(this));
        emit RemoveLike(1);
        removeLike(1);
        assertFalse(_likesMap[1][msg.sender]);
        assertFalse(getLiked(1));
    }

    function testAddLike() public {
        vm.expectEmit(true, false, false, false, address(this));
        _addLike(1);
        vm.expectRevert("Liked already");
        _addLike(1);
        assertTrue(_likesMap[1][msg.sender]);
        assertTrue(getLiked(1));
    }

    function testRemoveCommentLike() public {
        vm.expectRevert("Not liked before");
        removeLike(1, 1);
        _likesCommentsMap[1][1][msg.sender] = true;
        vm.expectEmit(true, true, false, false, address(this));
        emit RemoveLikeComment(1, 1);
        removeLike(1, 1);
        assertFalse(_likesCommentsMap[1][1][msg.sender]);
        assertFalse(getLikedComment(1, 1));
    }

    function testAddCommentLike() public {
        vm.expectEmit(true, true, false, false, address(this));
        _addLike(1, 1);
        vm.expectRevert("Liked already");
        _addLike(1, 1);
        assertTrue(_likesCommentsMap[1][1][msg.sender]);
        assertTrue(getLikedComment(1, 1));
    }

    function testLikeFee() public {
        _likeFeeProfit = 10;
        _likeAdminProfit = 50;
        vm.prank(owner());
        vm.expectRevert("Invalid fees for likes");
        setLikeFee(30);

        vm.prank(accounts[0]);
        vm.expectRevert("Ownable: caller is not the owner");
        setLikeFee(30);

        vm.prank(owner());
        setLikeFee(60);
        assertEq(_likeFee, 60);
        assertEq(getLikeFee(), 60);
    }

    function testAdminFee() public {
        _likeFeeProfit = 10;
        _likeFee = 20;
        vm.prank(owner());
        vm.expectRevert("Invalid fees for likes");
        setAdminFee(30);

        vm.prank(accounts[0]);
        vm.expectRevert("Ownable: caller is not the owner");
        setAdminFee(30);

        vm.prank(owner());
        setAdminFee(5);
        assertEq(_likeAdminProfit, 5);
        assertEq(getAdminFee(), 5);
    }

    function testOwnerFee() public {
        _likeAdminProfit = 10;
        _likeFee = 20;
        vm.prank(owner());
        vm.expectRevert("Invalid fees for likes");
        setLikeFeeProfit(30);

        vm.prank(accounts[0]);
        vm.expectRevert("Ownable: caller is not the owner");
        setLikeFeeProfit(30);

        vm.prank(owner());
        setLikeFeeProfit(5);
        assertEq(_likeFeeProfit, 5);
        assertEq(getLikeFeeProfit(), 5);
    }
}