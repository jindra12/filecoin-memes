// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import {MemeStorage} from "./MemeStorage.sol";
import {MemeEvents} from "./MemeEvents.sol";
import {MemeStructs} from "./MemeStructs.sol";
import {MemeLibrary} from "./MemeLibrary.sol";

abstract contract MemePayout is Ownable,MemeStructs,MemeEvents,MemeStorage {
    function withdrawOwner() public onlyOwner() {
        require(_ownerFees > 0, "Nothing to withdraw");
        (bool ok,) = owner().call{ value: _ownerFees }("");
        require(ok, "Transaction failed");
        _ownerFees = 0;
    }

    function withdrawAuthor() public {
        require(_authorsFees[msg.sender] > 0, "Nothing to withdraw");
        (bool ok,) = msg.sender.call{ value: _authorsFees[msg.sender] }("");
        require(ok, "Transaction failed");
        _authorsFees[msg.sender] = 0;
    }

    function getWithdrawableOwner() public view returns(uint256) {
        return _ownerFees;
    }

    function getWithdrawableAuthor() public view returns(uint256) {
        return _authorsFees[msg.sender];
    }
}