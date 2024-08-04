// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReverseRegistrar} from "../lib/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";
import { MarketAPI } from "filecoin-solidity-api/contracts/v0.8/MarketAPI.sol";
import { CommonTypes } from "filecoin-solidity-api/contracts/v0.8/types/CommonTypes.sol";
import { MarketTypes } from "filecoin-solidity-api/contracts/v0.8/types/MarketTypes.sol";
import { BigIntCBOR } from "filecoin-solidity-api/contracts/v0.8/cbor/BigIntCbor.sol";

contract MemePage is Ownable {
    constructor(ENS ens, string memory name, bytes32 addressReverseNode) {
        if (address(ens) != address(0)) {
            ReverseRegistrar reverseRegistrar = ReverseRegistrar(ens.owner(addressReverseNode));
            reverseRegistrar.claim(address(this));
            reverseRegistrar.setName(name);
        }
    }
}