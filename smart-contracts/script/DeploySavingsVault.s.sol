// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {SavingsVault} from "../src/SavingsVault.sol";

contract DeploySavingsVault is Script {
    SavingsVault vault;

    function run() public {
        vm.startBroadcast();
        vault = new SavingsVault();
        console.log("SavingsVault deployed at:", address(vault));
        vm.stopBroadcast();
    }
}