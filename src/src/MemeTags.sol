// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {MemeStorage} from "./MemeStorage.sol";
import {MemeEvents} from "./MemeEvents.sol";
import {MemeStructs} from "./MemeStructs.sol";
import {MemeLibrary} from "./MemeLibrary.sol";

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
}