// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {MemeStructs} from "../src/MemeStructs.sol";
import {Vm} from "forge-std/Vm.sol";

library TestLibrary {
    function getRandomTitle(uint256 from, uint256 to) public pure returns(string memory) {
        uint256 smallFrom = (from / 10) % 10;
        uint256 smallTo = to % 10;
        if (smallFrom > smallTo) {
            uint256 tmp = smallFrom;
            smallFrom = smallTo;
            smallTo = tmp;
        }
        string[] memory words = new string[](11);
        words[0] = "Hello";
        words[1] = "World";
        words[2] = "verbose";
        words[3] = "bad";
        words[4] = "good";
        words[5] = "weird";
        words[6] = "small";
        words[7] = "meme";
        words[8] = "funny";
        words[9] = "nine";
        words[10] = "eight";

        string memory acc = "";
        for (uint256 i = smallFrom; i < smallTo; i++) {
            acc = string.concat(acc, words[i]);
            if (i != smallTo - 1) {
                acc = string.concat(acc, " ");
            }
        }
        return acc;
    }
    function getLikesCount(uint256 count) public pure returns(uint256[] memory) {
        uint256[] memory likesCount = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            likesCount[i] = i % 2 == 0 ? i : count - i;
        }
        return likesCount;
    }
    function getAddresses(Vm vm, uint32 count) public returns(address[] memory) {
        address[] memory addresses = new address[](count);
        for (uint32 i = 0; i < count; i++) {
            (address addr,) = makeAccount(vm, i, 5);
            addresses[i] = addr;
        }
        return addresses;
    }
    function getTimeStamps(uint256 count) public view returns(uint256[] memory) {
        uint256[] memory timestamps = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            timestamps[i] = i % 2 == 1 ? (block.timestamp + i) : (block.timestamp + count - i);
        }
        return timestamps;
    }
    function populatePosts(MemeStructs.Post[] storage acc, uint256 postCount, address[] memory addresses, uint256[] memory timestamps, uint256[] memory likesCount) public returns(MemeStructs.Post[] memory) {
        for (uint256 i = 0; i < postCount; i++) {
            MemeStructs.Post memory post;
            post.id = i;
            if (i >= addresses.length) {
                post.author = msg.sender;
            } else {
                post.author = addresses[i];
            }
            if (i >= timestamps.length) {
                post.time = block.timestamp;
            } else {
                post.time = timestamps[i];
            }
            if (i >= likesCount.length) {
                post.likes.likesCount = i;
            } else {
                post.likes.likesCount = likesCount[i];
            }
            post.content = getRandomTitle(0, 10);
            post.title = getRandomTitle(i, postCount - i);
            post.time = block.timestamp;
            acc.push(post);
        }

        return acc;
    }
    function populatePosts(Vm vm, MemeStructs.Post[] storage acc, uint256 postCount) public returns(MemeStructs.Post[] memory) {
        return populatePosts(acc, postCount, getAddresses(vm, uint32(postCount)), getTimeStamps(postCount), getLikesCount(postCount));
    }
    function populateComments(MemeStructs.Comment[] storage acc, uint256 commentCount, address[] memory addresses, uint256[] memory timestamps) public returns(MemeStructs.Comment[] memory) {
        for (uint256 i = 0; i < commentCount; i++) {
            MemeStructs.Comment memory comment;
            comment.id = i;
            if (i >= addresses.length) {
                comment.author = msg.sender;
            } else {
                comment.author = addresses[i];
            }
            if (i >= timestamps.length) {
                comment.time = block.timestamp;
            } else {
                comment.time = timestamps[i];
            }
            comment.content = getRandomTitle(0, 10);
            comment.time = block.timestamp;
            acc.push(comment);
        }

        return acc;
    }

    function populateComments(Vm vm, MemeStructs.Comment[] storage acc, uint256 commentCount) public returns(MemeStructs.Comment[] memory) {
        return populateComments(acc, commentCount, getAddresses(vm, uint32(commentCount)), getTimeStamps(commentCount));
    }

    function makeAccount(Vm vm, uint32 random, uint256 funds) internal returns(address,bool) {
        string memory mnemonic = "test test test test test test test test test test test junk";
        uint256 privateKey = vm.deriveKey(mnemonic, random);
        address addr = vm.addr(privateKey);
        (bool ok,) = addr.call{ value: funds }("");
        return (addr,ok);
    }
}