// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SqrtSolver.sol";
import "../src/IOptimizor.sol";

import "forge-std/console.sol";

contract SqrtTest is Test {
    ISqrt public sqrt;
    SqrtSolver public solver;
    IOptimizor optimizor;

    function setUp() public {
    }

    function test_solve() public {
        bytes memory bytecode = hex"60268060093d393df36006318060181c595262ffffff16595258318060181c595262ffffff165952475952596005f3";

        address sqrt_addr;
        assembly {
            sqrt_addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        vm.deal(sqrt_addr, 0);
        console.log("sqrt deployed to: %s, %s", sqrt_addr, sqrt_addr.balance);

        address[5] memory holders = [
            0x0000000000000000000000000000000000000006,
            0x0000000000000000000000000000000000000010,
            0x000000000000000000000000000000000000BeE2,
            0x000000000000000000000000000000000000Bee3,
            sqrt_addr
        ];

        sqrt = ISqrt(sqrt_addr);
        solver = new SqrtSolver();
        optimizor = IOptimizor(0x66DE7D67CcfDD92b4E5759Ed9dD2d7cE3C9154a9);

        // commit to solution
        bytes32 key = keccak256(abi.encode(address(this), sqrt_addr.codehash, 0x777));
        console.log("commit:", uint256(key));
        optimizor.commit(key);

        // pass time
        vm.difficulty(0x66DE7D67CcfDD92b4E5759Ed9dD2d7cE3C9154a954a954a954a9);
        vm.roll(block.number + 66);

        console.log("solve:", block.difficulty);
        uint256[5] memory solution = solver.solve(sqrt_addr, block.difficulty);

        vm.deal(address(this), 100e18);
        // for (uint256 i = 0; i < holders.length; i++) {
        //     payable(holders[i]).send(solution[i] >> 32);
        //     console.log("paid: %s -> %s", solution[i], holders[i].balance);
        // }

        uint256 pay0 = (solution[1] >> 40) | (((solution[0] >> 40) & 0xffffff) << 24);
        uint256 pay1 = (solution[3] >> 40) | (((solution[2] >> 40) & 0xffffff) << 24);
        console.log("pay: %s, %s", pay0, pay1);

        payable(holders[0]).send(pay0-holders[0].balance);
        payable(holders[1]).send(pay1-holders[1].balance);
        payable(holders[4]).send(solution[4] >> 40);
        console.log("balance: %s, %s", holders[0].balance, holders[1].balance);

        console.log("challenge...");
        optimizor.challenge(1, sqrt_addr, address(this), 0x777);
        require(optimizor.balanceOf(address(this)) > 0, "no NFT?");
        console.log("challenge success");

        (address code, address solver, uint32 gas) = optimizor.extraDetails(4294967308);
        console.log("gas used:", gas);
    }
}
