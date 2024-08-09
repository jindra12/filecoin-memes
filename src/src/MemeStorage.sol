// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {MemeStructs} from "./MemeStructs.sol";

abstract contract MemeStorage is MemeStructs {
    mapping(uint256 => mapping(address => bool)) internal _likesMap;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) internal _likesCommentsMap;
    mapping(uint256 => uint256) internal _postsMap;

    mapping(uint256 => uint256[]) internal _postToday;
    mapping(uint256 => uint256[]) internal _postWeek;
    mapping(uint256 => uint256[]) internal _postMonth;

    mapping(address => uint256[]) internal _postsByAuthor;

    mapping(uint256 => mapping(uint256 => uint256[])) internal _commentToday;
    mapping(uint256 => mapping(uint256 => uint256[])) internal _commentWeek;
    mapping(uint256 => mapping(uint256 => uint256[])) internal _commentMonth;

    mapping(uint256 => mapping(uint256 => bool)) internal _postsByTag;
    mapping(uint256 => string) internal _tagNames;
    mapping(uint256 => uint256) internal _tagPopularities;

    uint256 internal _ownerFees = 0;
    mapping(address => uint256) internal _authorsFees;

    Tag[] internal _bestTags;
    uint256 internal _bestTagsLimit;

    Post[] internal _posts;
    mapping(uint256 => uint256) _postIndex;

    Comment[] internal _comments;
    mapping(uint256 => uint256) _commentIndex;

    uint256 internal _postId = 1;
    uint256 internal _commentId = 1;
    uint256 internal _likeFee = 0;
    uint256 internal _likeFeeProfit = 0;

    uint256 internal _giveUpLimit = 5000;
}