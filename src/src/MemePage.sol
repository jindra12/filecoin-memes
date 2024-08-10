// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {AccessControlEnumerable} from "../lib/openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import {MemePosts} from "./MemePosts.sol";
import {MemeComments} from "./MemeComments.sol";
import {MemeLikes} from "./MemeLikes.sol";

contract MemePage is MemeLikes,MemePosts,MemeComments {
    constructor(uint256 likeFee, uint256 likeFeeProfit, uint256 adminProfit, ENS ens, string memory name, bytes32 addressReverseNode) {
        require(likeFee > likeFeeProfit, "Invalid fees for likes");
        _likeFee = likeFee;
        _likeFeeProfit = likeFeeProfit;
        _likeAdminProfit = adminProfit;

        _setRoleAdmin(MOD_ROLE, ADMIN_MOD_ROLE);
        _setupRole(MOD_ROLE, msg.sender);
        _setupRole(ADMIN_MOD_ROLE, msg.sender);

        if (address(ens) != address(0)) {
            ReverseRegistrar reverseRegistrar = ReverseRegistrar(ens.owner(addressReverseNode));
            reverseRegistrar.claim(address(this));
            reverseRegistrar.setName(name);
        }
    }
}