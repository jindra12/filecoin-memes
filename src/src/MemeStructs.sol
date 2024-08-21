// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";

interface MemeStructs {
    struct Likes {
        uint256 likesCount;
        address[] likes;
    }
    
    enum ReplyToType {
        POST,
        COMMENT
    }

    enum SortType {
        TIME,
        HOT,
        LIKE
    }

    enum FilterType {
        DAY,
        WEEK,
        MONTH,
        LATEST
    }

    struct ReplyTo {
        ReplyToType replyType;
        uint256 id;
    }

    struct Comment {
        uint256 id;
        address author;
        string content;
        uint256 time;
        uint256 editTime;
        Likes likes;
        uint256 replyTo;
    }
    
    struct Post {
        uint256 id;
        address author;
        uint256 time;
        uint256 editTime;
        string title;
        string content;
        Likes likes;
        uint256[] commentIds;
        uint256[] tagIds;
        uint256 replyTo;
    }

    struct Tag {
        string name;
        uint256 hash;
        uint256 popularity;
    }
}