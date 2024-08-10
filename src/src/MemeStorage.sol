// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
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
    uint256 internal _currentAdminRewardIndex;
    mapping(address => uint256) internal _authorsFees;
    mapping(address => uint256) internal _adminFees;

    Tag[] internal _bestTags;
    uint256 internal _bestTagsLimit;

    Post[] internal _posts;
    mapping(uint256 => uint256) _postIndex;

    Comment[] internal _comments;
    mapping(uint256 => uint256) _commentIndex;

    uint256 internal _postId = 1;
    uint256 internal _commentId = 1;
    uint256 internal _likeFee = 2;
    uint256 internal _likeFeeProfit = 1;
    uint256 internal _likeAdminProfit = 1;

    uint256 internal _giveUpLimit = 5000;

    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");
    bytes32 public constant ADMIN_MOD_ROLE = keccak256("ADMIN_MOD_ROLE");
}