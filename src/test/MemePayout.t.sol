// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MemePayout} from "../src/MemePayout.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {TestLibrary} from "./TestLibrary.sol";

contract MemePayoutTest is Test,MemePayout {
    address[] public accounts;
    uint256 _accountCount = 10;

    function setUp() public {
        for (uint256 i = 0; i < _accountCount; i++) {
            (address acc,) = TestLibrary.makeAccount(vm, uint32(i), 50);
            accounts.push(acc);
        }
        _postIndex[1] = 0;
        Post memory post;
        post.author = accounts[4];
        _posts.push(post);

        _commentIndex[1] = 0;
        Comment memory comment;
        comment.author = accounts[5];
        _comments.push(comment);

        _grantRole(MOD_ROLE, accounts[0]);
        _grantRole(MOD_ROLE, accounts[1]);
        _grantRole(MOD_ROLE, accounts[2]);

        _likeFee = 50;
        _likeAdminProfit = 10;
        _likeFeeProfit = 10;
    }

    function testDistributeReward() public {
        _distributeReward(accounts[4]);

        assertEq(_authorsFees[accounts[4]], 30);
        assertEq(_ownerFees, 10);
        assertEq(_adminFees[accounts[0]], 10);

        vm.prank(accounts[4]);
        assertEq(getWithdrawableAuthor(), 30);
        assertEq(getWithdrawableOwner(), 10);
        vm.prank(accounts[0]);
        assertEq(getWithdrawableAdmin(), 10);
    }

    function testDistributeRewardPost() public {
        _distributeRewardPost(1);

        assertEq(_authorsFees[accounts[4]], 60);
        assertEq(_ownerFees, 20);
        assertEq(_adminFees[accounts[1]], 10);

        vm.prank(accounts[4]);
        assertEq(getWithdrawableAuthor(), 60);
        assertEq(getWithdrawableOwner(), 20);
        vm.prank(accounts[1]);
        assertEq(getWithdrawableAdmin(), 10);
    }

    function testDistributeRewardComment() public {
        _distributeRewardComment(1);

        assertEq(_authorsFees[accounts[5]], 30);
        assertEq(_ownerFees, 30);
        assertEq(_adminFees[accounts[2]], 10);

        vm.prank(accounts[4]);
        assertEq(getWithdrawableAuthor(), 30);
        assertEq(getWithdrawableOwner(), 30);
        vm.prank(accounts[2]);
        assertEq(getWithdrawableAdmin(), 10);
    }

    function testGetAndMoveAdminRewarded() public {
        address admin = _getAndMoveAdminRewarded();
        assertEq(admin, accounts[0]);
    }

    function testWithdrawOwner() public {
        vm.expectCall(owner(), 30, "");
        vm.prank(owner());
        withdrawOwner();
        assertEq(_ownerFees, 0);
    }

    function testWithdrawAuthor() public {
        vm.expectCall(accounts[4], 60, "");
        vm.prank(accounts[4]);
        withdrawAuthor();
        assertEq(_authorsFees[accounts[4]], 0);
    }

    function testWithdrawAdmin() public {
        vm.expectCall(accounts[0], 10, "");
        vm.prank(accounts[0]);
        withdrawAdmin();
        assertEq(_adminFees[accounts[0]], 0);
    }

    function testGetWithdrawableOwner() public view {
        assertEq(getWithdrawableOwner(), 0);
    }

    function testGetWithdrawableAuthor() public {
        vm.prank(accounts[5]);
        assertEq(getWithdrawableAuthor(), 30);
    }

    function testGetWithdrawableAdmin() public {
        vm.prank(accounts[2]);
        assertEq(getWithdrawableAdmin(), 10);
    }
}