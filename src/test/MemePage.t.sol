// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MemePage} from "../src/MemePage.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ENS} from "../lib/ens-contracts/contracts/registry/ENS.sol";

contract MemePageTest is Test {
    MemePage public memePage;

    function setUp() public {
        memePage = new MemePage(50, 5, 5, ENS(address(0)), "", 0x0);
    }
}