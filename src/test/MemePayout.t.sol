// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MemePayout} from "../src/MemePayout.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {TestLibrary} from "./TestLibrary.sol";

contract MemePayoutInternal is MemePayout {
    constructor(address[] memory accounts) {
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

    function distributeRewardTest(address author) public {
        _distributeReward(author);
    }

    function distributeRewardPostTest(uint256 postId) public {
        _distributeRewardPost(postId);
    }

    function distributeRewardCommentTest(uint256 commentId) public {
        _distributeRewardComment(commentId);
    }

    function getAndMoveAdminRewardedTest() public returns(address) {
        return _getAndMoveAdminRewarded();
    }

    receive() external payable {}
}

contract MemePayoutTest is Test {
    address[] public accounts;
    uint256 _accountCount = 10;

    MemePayoutInternal public memePayout;

    function setUp() public {
        for (uint256 i = 0; i < _accountCount; i++) {
            (address acc,) = TestLibrary.makeAccount(vm, uint32(i), 50);
            accounts.push(acc);
        }
        vm.prank(accounts[9]);
        memePayout = new MemePayoutInternal(accounts);
    }

    function testDistributeReward() public {
        memePayout.distributeRewardTest(accounts[4]);

        vm.prank(accounts[4]);
        assertEq(memePayout.getWithdrawableAuthor(), 30);
        assertEq(memePayout.getWithdrawableOwner(), 10);
        vm.prank(accounts[0]);
        assertEq(memePayout.getWithdrawableAdmin(), 10);
    }

    function testDistributeRewardPost() public {
        memePayout.distributeRewardPostTest(1);

        vm.prank(accounts[4]);
        assertEq(memePayout.getWithdrawableAuthor(), 30);
        assertEq(memePayout.getWithdrawableOwner(), 10);
        vm.prank(accounts[0]);
        assertEq(memePayout.getWithdrawableAdmin(), 10);

        memePayout.distributeRewardPostTest(1);
        vm.prank(accounts[1]);
        assertEq(memePayout.getWithdrawableAdmin(), 10);
    }

    function testDistributeRewardComment() public {
        memePayout.distributeRewardCommentTest(1);

        vm.prank(accounts[5]);
        assertEq(memePayout.getWithdrawableAuthor(), 30);
        assertEq(memePayout.getWithdrawableOwner(), 10);

        memePayout.distributeRewardCommentTest(1);
        vm.prank(accounts[1]);
        assertEq(memePayout.getWithdrawableAdmin(), 10);

        memePayout.distributeRewardCommentTest(2);
        vm.prank(accounts[2]);
        assertEq(memePayout.getWithdrawableAdmin(), 10);
    }

    function testGetAndMoveAdminRewarded() public {
        address admin = memePayout.getAndMoveAdminRewardedTest();
        assertEq(admin, accounts[0]);
        address admin1 = memePayout.getAndMoveAdminRewardedTest();
        assertEq(admin1, accounts[1]);
        address admin2 = memePayout.getAndMoveAdminRewardedTest();
        assertEq(admin2, accounts[2]);
        address admin3 = memePayout.getAndMoveAdminRewardedTest();
        assertEq(admin3, accounts[0]);
    }

    function testWithdrawOwner() public {
        vm.prank(accounts[6]);
        (bool ok,) = address(memePayout).call{ value: 50 }("");
        assertTrue(ok);
        memePayout.distributeRewardTest(accounts[4]);
        vm.expectCall(memePayout.owner(), 10, "");
        vm.prank(memePayout.owner());
        memePayout.withdrawOwner();
        assertEq(memePayout.getWithdrawableOwner(), 0);
    }

    function testWithdrawAuthor() public {
        memePayout.distributeRewardPostTest(1);
        vm.prank(accounts[6]);
        (bool ok,) = address(memePayout).call{ value: 50 }("");
        assertTrue(ok);
        vm.expectCall(accounts[4], 30, "");
        vm.prank(accounts[4]);
        memePayout.withdrawAuthor();
        vm.prank(accounts[4]);
        assertEq(memePayout.getWithdrawableAuthor(), 0);
    }

    function testWithdrawAdmin() public {
        memePayout.distributeRewardCommentTest(1);
        vm.prank(accounts[6]);
        (bool ok,) = address(memePayout).call{ value: 50 }("");
        assertTrue(ok);
        vm.expectCall(accounts[0], 10, "");
        vm.prank(accounts[0]);
        memePayout.withdrawAdmin();
        vm.prank(accounts[0]);
        assertEq(memePayout.getWithdrawableAdmin(), 0);
    }
}