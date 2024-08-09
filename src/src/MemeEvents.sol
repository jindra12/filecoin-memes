// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";

interface MemeEvents {
    event AddLike(uint256 indexed postId);
    event AddLikeComment(uint256 indexed postId, uint256 indexed commentId);
    event PostAdded(uint256 indexed postId, string indexed title);
    event PostEdited(uint256 indexed postId, string indexed title);
    event PostDeleted(uint256 indexed postId, string indexed title);
    event CommentAdded(uint256 indexed postId, string indexed title);
    event CommentEdited(uint256 indexed postId, string indexed title);
    event CommentDeleted(uint256 indexed postId, string indexed title);
    event TagAdded(string indexed name);
}