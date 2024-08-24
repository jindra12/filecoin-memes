// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MemeStorage} from "./MemeStorage.sol";
import {MemeEvents} from "./MemeEvents.sol";
import {MemeStructs} from "./MemeStructs.sol";

abstract contract MemeTags is Ownable,MemeStructs,MemeEvents,MemeStorage {
    function _addTag(Tag memory tag) internal {
        _tagNames[tag.hash] = tag.name;
        _tagPopularities[tag.hash] += 1;
        tag.popularity = _tagPopularities[tag.hash];

        if (_bestTags.length < _bestTagsLimit) {
            _bestTags.push(tag);
        } else {
            uint256 smallestPop = _bestTags[0].popularity;
            for (uint256 i = 1; i < _bestTags.length; i++) {
                if (smallestPop > _bestTags[i].popularity) {
                    smallestPop = _bestTags[i].popularity;
                }
            }
            for (uint256 i = 0; i < _bestTags.length; i++) {
                if (_bestTags[i].popularity == smallestPop) {
                    _bestTags[i] = tag;
                    break;
                }
            }
        }
    }

    function _createTags(uint256 postId, string[] memory tags) internal {
        for (uint256 i = 0; i < tags.length; i++) {
            Tag memory tag;
            tag.name = tags[i];
            tag.hash = uint256(keccak256(bytes(tags[i])));
            _addTag(tag);
            _postsByTag[tag.hash][postId] = true;
            _posts[_posts.length - 1].tagIds.push(tag.hash);
            emit TagAdded(tag.name);
        }
    }

    function _updateTags(uint256 postId) internal {
        Post storage post = _posts[_postIndex[postId]];
        for (uint256 i = 0; i < post.tagIds.length; i++) {
            Tag memory tag;
            tag.name = _tagNames[post.tagIds[i]];
            tag.hash = post.tagIds[i];
            _addTag(tag);
        }
    }
}