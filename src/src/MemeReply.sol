// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {MemeStorage} from "./MemeStorage.sol";
import {MemeStructs} from "./MemeStructs.sol";

abstract contract MemeReply is MemeStorage {
    function _verifyReply(MemeStructs.ReplyToType replyType, uint256 id) internal view {
        if (replyType == MemeStructs.ReplyToType.POST) {
            require(_posts[_postIndex[id]].id == id, "Post does not exist");
        } else if (replyToType == MemeStructs.ReplyToType.COMMENT) {
            require(_comments[_commentsIndex[id]].id == id, "Comment does not exist");
        }
    }
}