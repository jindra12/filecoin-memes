// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";

interface MemeEvents {
    event AddLike(uint256 indexed postId);
    event AddLikeComment(uint256 indexed postId, uint256 indexed commentId);
    event RemoveLike(uint256 indexed postId);
    event RemoveLikeComment(uint256 indexed postId, uint256 indexed commentId);
    event SetAdminLikeFee(uint256 indexed amount);
    event SetLikeFee(uint256 indexed amount);
    event SetLikeFeeProfit(uint indexed amount);
    event PostAdded(uint256 indexed postId, string indexed title);
    event PostEdited(uint256 indexed postId, string indexed title);
    event PostRemoved(uint256 indexed postId, string indexed title, address indexed by);
    event CommentAdded(uint256 indexed postId, uint256 indexed commentId);
    event CommentEdited(uint256 indexed commentId);
    event CommentRemoved(uint256 indexed commentId, address indexed by);
    event TagAdded(string indexed name);
    event WithdrawOwner(uint256 indexed amount);
    event WithdrawAuthor(uint256 indexed amount, address indexed author);
    event WithdrawAdmin(uint256 indexed amount, address indexed admin);
}