// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SavingsVault} from "../src/SavingsVault.sol";

contract SavingsVaultTest is Test {
    SavingsVault vault;
    address user1;
    address user2;


    /////////////////////////////////////////////
    //                SETUP                   //
    ///////////////////////////////////////////

    function setUp() public {
        vault = new SavingsVault();
        user1 = vm.addr(1);
        user2 = vm.addr(2);
        vm.deal(user1, 10 ether);
        vm.deal(user2, 5 ether);
    }


    /////////////////////////////////////////////
    //             BASIC TESTS                //
    ///////////////////////////////////////////

    function testCreateGoal() public {
        vm.prank(user1);
        vault.createGoal(1 ether, "MacBook", "Saving up for a Mac");

        SavingsVault.Goal memory goal = vault.getGoal(user1, 0);
        assertEq(goal.name, "MacBook");
        assertEq(goal.description, "Saving up for a Mac");
        assertFalse(goal.targetReached);
    }

    function testDepositAndReachTarget() public {
        vm.startPrank(user1);
        vault.createGoal(1 ether, "Trip", "Goa trip");
        vault.deposit{value: 1 ether}(0);

        SavingsVault.Goal memory goal = vault.getGoal(user1, 0);
        assertEq(goal.amountSaved, 1 ether);
        assertTrue(goal.targetReached);
    }

    function testWithdrawOnlyAfterTargetReached() public {
        vm.startPrank(user1);
        vault.createGoal(1 ether, "Phone", "New phone");
        vault.deposit{value: 0.5 ether}(0);

        vm.expectRevert(SavingsVault.SavingsVault__TargetNotYetReached.selector);
        vault.withdraw(0);

        vault.deposit{value: 0.5 ether}(0);
        vault.withdraw(0);

        SavingsVault.Goal memory goal = vault.getGoal(user1, 0);
        assertEq(goal.amountSaved, 0);
    }

    function testSetUsername() public {
        vm.prank(user2);
        vault.setUsername("ayxhmn");

        string memory uname = vault.getUsername(user2);
        assertEq(uname, "ayxhmn");
    }

    function testGetAllGoals() public {
        vm.startPrank(user1);
        vault.createGoal(1 ether, "A", "A desc");
        vault.createGoal(2 ether, "B", "B desc");

        SavingsVault.Goal[] memory goals = vault.getAllGoals(user1);
        assertEq(goals.length, 2);
        assertEq(goals[1].name, "B");
    }


    /////////////////////////////////////////////
    //            EDGE CASE TESTS             //
    ///////////////////////////////////////////

    function testRevertWhenGoalIdInvalidOnDeposit() public {
        vm.prank(user1);
        vm.expectRevert(SavingsVault.SavingsVault__GoalDoesNotExist.selector);
        vault.deposit{value: 1 ether}(0);
    }

    function testRevertWhenGoalIdInvalidOnWithdraw() public {
        vm.prank(user1);
        vm.expectRevert(SavingsVault.SavingsVault__GoalDoesNotExist.selector);
        vault.withdraw(0); // never created a goal
    }

    function testRevertIfGoalAlreadyReached() public {
        vm.startPrank(user1);
        vault.createGoal(1 ether, "Goal", "desc");
        vault.deposit{value: 1 ether}(0);

        // goal reached
        vm.expectRevert(SavingsVault.SavingsVault__TargetAlreadyReached.selector);
        vault.deposit{value: 0.1 ether}(0);
    }

    function testRevertOnZeroTarget() public {
        vm.prank(user1);
        vm.expectRevert(SavingsVault.SavingsVault__TargetMustBeGreaterThanZero.selector);
        vault.createGoal(0, "Invalid", "Should fail");
    }


    /////////////////////////////////////////////
    //              FUZZ TESTS                //
    ///////////////////////////////////////////

    function testFuzzGoalCreation(uint256 amount, string memory name, string memory desc) public {
        vm.assume(amount > 0 && amount <= 100 ether);
        vm.prank(user1);
        vault.createGoal(amount, name, desc);

        SavingsVault.Goal memory goal = vault.getGoal(user1, 0);
        assertEq(goal.targetAmount, amount);
        assertEq(goal.name, name);
        assertEq(goal.description, desc);
    }

    function testFuzzDepositAndWithdraw(uint96 depositAmount) public {
        vm.assume(depositAmount > 1 ether && depositAmount <= 10 ether);
        vm.startPrank(user1);
        vault.createGoal(depositAmount, "Laptop", "Just fuzzing");

        vault.deposit{value: depositAmount}(0);
        SavingsVault.Goal memory goal = vault.getGoal(user1, 0);
        assertEq(goal.amountSaved, depositAmount);
        assertTrue(goal.targetReached);

        uint256 balanceBefore = user1.balance;
        vault.withdraw(0);
        uint256 balanceAfter = user1.balance;

        assertEq(balanceAfter, balanceBefore + depositAmount);
    }
}