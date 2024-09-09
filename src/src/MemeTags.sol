// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MemeStorage} from "./MemeStorage.sol";
import {MemeEvents} from "./MemeEvents.sol";
import {MemeStructs} from "./MemeStructs.sol";

abstract contract MemeTags is Ownable,MemeStructs,MemeEvents,MemeStorage {
    function _removeWorstBestTag() internal {
        if (_bestTags.length != 0) {
            uint256 smallestPop = _bestTags[0].popularity;
            for (uint256 i = 1; i < _bestTags.length; i++) {
                if (smallestPop > _bestTags[i].popularity) {
                    smallestPop = _bestTags[i].popularity;
                }
            }
            for (uint256 i = 0; i < _bestTags.length; i++) {
                if (_bestTags[i].popularity == smallestPop) {
                    if (i != _bestTags.length - 1) {
                        Tag memory lastTag = _bestTags[_bestTags.length - 1];
                        _bestTags.pop();
                        _bestTags[i] = lastTag;
                    } else {
                        _bestTags.pop();
                    }
                    break;
                }
            }
        }
    }
    function _replaceWorstBestTag(Tag memory tag) internal {
        if (_bestTags.length != 0) {
            uint256 smallestPop = _bestTags[0].popularity;
            bool found = false;
            for (uint256 i = 0; i < _bestTags.length; i++) {
                if (found) {
                    break;
                }
                found = _bestTags[i].hash == tag.hash;
            }
            if (!found) {
                for (uint256 i = 1; i < _bestTags.length; i++) {
                    if (smallestPop > _bestTags[i].popularity) {
                        smallestPop = _bestTags[i].popularity;
                    }
                }
                for (uint256 i = 0; i < _bestTags.length; i++) {
                    if (_bestTags[i].popularity == smallestPop && tag.popularity > smallestPop) {
                        _bestTags[i] = tag;
                        break;
                    }
                }
            }
        }
    }

    function _addTag(Tag memory tag) internal returns(bool) {
        bool hasTag = _tagPopularities[tag.hash] != 0;
        _tagNames[tag.hash] = tag.name;
        _tagPopularities[tag.hash] += 1;
        tag.popularity = _tagPopularities[tag.hash];

        if (_bestTags.length < _bestTagsLimit) {
            if (!hasTag) {
                _bestTags.push(tag);
            }
        } else {
            _replaceWorstBestTag(tag);
        }

        return !hasTag;
    }

    function getBestTags() public view returns(Tag[] memory) {
        return _bestTags;
    }

    function setBestTagLimit(uint256 limit) public onlyOwner() {
        _bestTagsLimit = limit;
        if (limit < _bestTags.length) {
            uint256 removeCount = _bestTags.length - limit;
            for (uint i = 0; i < removeCount; i++) {
                _removeWorstBestTag();
            }
        }
    }

    function _createTags(uint256 postId, string[] memory tags) internal {
        for (uint256 i = 0; i < tags.length; i++) {
            Tag memory tag;
            tag.name = tags[i];
            tag.hash = uint256(keccak256(bytes(tags[i])));
            if (_addTag(tag)) {
                _postsByTag[tag.hash][postId] = true;
                _posts[_postIndex[postId]].tagIds.push(tag.hash);
                emit TagAdded(tag.name);
            }
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