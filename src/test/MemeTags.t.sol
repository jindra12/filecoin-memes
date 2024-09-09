// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MemeTags} from "../src/MemeTags.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {TestLibrary} from "./TestLibrary.sol";

contract MemeTagsTest is Test,MemeTags {
    address[] public accounts;
    uint256 _accountCount = 10;

    function setUp() public {
        for (uint256 i = 0; i < _accountCount; i++) {
            (address acc,) = TestLibrary.makeAccount(vm, uint32(i), 50);
            accounts.push(acc);
        }
        _postIndex[1] = 0;
        Post memory post;
        _posts.push(post);
        _bestTagsLimit = 10;
    }

    function testCreateTags() public {
        string[] memory tags = new string[](5);
        tags[0] = "My";
        tags[1] = "Name";
        tags[2] = "Is";
        tags[3] = "Johnny";
        tags[4] = "Waters";
        _createTags(1, tags);
        assertEq(_bestTags.length, 5);
        assertEq(_bestTags[0].name, "My");
        assertEq(_bestTags[1].name, "Name");
        assertEq(_bestTags[2].name, "Is");
        assertEq(_bestTags[3].name, "Johnny");
        assertEq(_bestTags[4].name, "Waters");
        setBestTagLimit(3);
        assertEq(_bestTags.length, 3);
        assertEq(_bestTags[2].name, "Is");
        assertEq(_bestTags[1].name, "Name");
        assertEq(_bestTags[0].name, "Johnny");
        string[] memory next = new string[](2);
        next[0] = "Johnny";
        next[1] = "Waters";
        _createTags(1, next);
        assertEq(_bestTags.length, 3);
        assertEq(_bestTags[2].name, "Is");
        assertEq(_bestTags[1].name, "Name");
        assertEq(_bestTags[0].name, "Waters");
        assertEq(_bestTags[0].hash, uint256(keccak256("Waters")));
        string[] memory next1 = new string[](2);
        next1[0] = "Johnny";
        next1[1] = "Waters";
        _createTags(1, next1);
        assertEq(_tagPopularities[uint256(keccak256("Is"))], 1);
        assertEq(_tagPopularities[uint256(keccak256("Johnny"))], 3);
        assertEq(_tagPopularities[uint256(keccak256("Waters"))], 3);
        assertEq(_bestTags[1].name, "Johnny");

        for (uint256 i = 0; i < 5; i++) {
            string[] memory next2 = new string[](1);
            next2[0] = "Next";
            _createTags(1, next2);
        }
        assertEq(_tagPopularities[uint256(keccak256("Next"))], 5);
        assertEq(_bestTags[2].name, "Next");
        assertEq(_bestTags[1].name, "Johnny");
        assertEq(_bestTags[0].name, "Waters");
    }

    function testUpdateTags() public {
        _posts[0].tagIds.push(uint256(keccak256("My")));
        _posts[0].tagIds.push(uint256(keccak256("Name")));
        _updateTags(1);
        assertEq(_tagPopularities[uint256(keccak256("My"))], 1);
        assertEq(_tagPopularities[uint256(keccak256("Name"))], 1);
        _updateTags(1);
        assertEq(_tagPopularities[uint256(keccak256("My"))], 2);
        assertEq(_tagPopularities[uint256(keccak256("Name"))], 2);
        assertEq(_bestTags.length, 2);
    }
}