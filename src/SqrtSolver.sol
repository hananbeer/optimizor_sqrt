pragma solidity ^0.8.17;

import "forge-std/console.sol";

type Fixed18 is uint256;

uint256 constant FIXED18BASE = 10 ** 18;

function add(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap(Fixed18.unwrap(a) + Fixed18.unwrap(b));
}

function sub(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap(Fixed18.unwrap(a) - Fixed18.unwrap(b));
}

function mul(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap((Fixed18.unwrap(a) * Fixed18.unwrap(b)) / FIXED18BASE);
}

function div(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap((Fixed18.unwrap(a)) / Fixed18.unwrap(b));
}

function distance(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    uint256 _a = Fixed18.unwrap(a);
    uint256 _b = Fixed18.unwrap(b);
    unchecked {
        if (_a < _b) {
            return Fixed18.wrap(_b - _a);
        } else {
            return Fixed18.wrap(_a - _b);
        }
    }
}

function lt(Fixed18 a, Fixed18 b) pure returns (bool) {
    return Fixed18.unwrap(a) < Fixed18.unwrap(b);
}

function le(Fixed18 a, Fixed18 b) pure returns (bool) {
    return Fixed18.unwrap(a) <= Fixed18.unwrap(b);
}

function gt(Fixed18 a, Fixed18 b) pure returns (bool) {
    return Fixed18.unwrap(a) > Fixed18.unwrap(b);
}

function bit_and(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap(Fixed18.unwrap(a) & Fixed18.unwrap(b));
}

function bit_xor(Fixed18 a, Fixed18 b) pure returns (Fixed18) {
    return Fixed18.wrap(Fixed18.unwrap(a) ^ Fixed18.unwrap(b));
}

using {add, sub, mul, div, distance, lt, le, gt, bit_and, bit_xor} for Fixed18 global;

uint256 constant INPUT_SIZE = 5;

// Expecting 5 decimal places of precision.
Fixed18 constant EPSILON = Fixed18.wrap(0.0001 * 10 ** 18);

interface ISqrt {
    function sqrt(Fixed18[INPUT_SIZE+1] calldata data) external returns (uint256[INPUT_SIZE] memory);
}

function random_fixed18(uint256 seed) pure returns (Fixed18) {
    return Fixed18.wrap(uint256(random_uint64(seed)));
}

function random_uint64(uint256 seed) pure returns (uint64) {
    return uint64(uint256(keccak256(abi.encodePacked(seed))));
}

contract SqrtSolver {
      function calc_sqrt(Fixed18 x) public pure returns (Fixed18 y) {
        Fixed18 z = x.add(Fixed18.wrap(1)).div(Fixed18.wrap(2));
        y = x;
        while (z.lt(y)) {
            y = z;
            z = (x.div(z).add(z)).div(Fixed18.wrap(2));
        }
    }
    
    function solve(address target, uint256 seed) external returns (uint256[INPUT_SIZE] memory) {
        // generate solutions
        // when input size is larger than expected it performs a storage write
        // (hence the +1)
        uint256[INPUT_SIZE] memory sqrts;
        Fixed18[INPUT_SIZE] memory inputs;
        unchecked {
            for (uint256 i = 0; i < INPUT_SIZE; ++i) {
                inputs[i] = random_fixed18(seed);
                seed = Fixed18.unwrap(inputs[i]);
                sqrts[i] = Fixed18.unwrap(calc_sqrt(Fixed18.wrap(1e18 * Fixed18.unwrap(inputs[i]))));
            }
        }

        // return sqrts;

        for (uint256 i = 0; i < INPUT_SIZE; ++i) {
            console.log("verifying input: %s", 1e18 * Fixed18.unwrap(inputs[i]));
            console.log("verifying sqrts: %s", sqrts[i]);
            verify(inputs[i], Fixed18.wrap(sqrts[i]));
        }

        return sqrts;

/*
        console.log("committing sqrts...");
        //console.logBytes(abi.encode(sqrts));
        Fixed18[INPUT_SIZE] memory outputs = ISqrt(target).sqrt(sqrts);
        //console.logBytes(abi.encodePacked(outputs));

        for (uint256 i = 0; i < INPUT_SIZE; ++i) {
            // console.log("verifying input: %s", Fixed18.unwrap(inputs[i]));
            console.log("verifying output: %s", Fixed18.unwrap(outputs[i]));
            verify(inputs[i], outputs[i]);
        }
        */
    }

    // Reverts if invalid
    function verify(Fixed18[INPUT_SIZE] memory inputs, Fixed18[INPUT_SIZE] memory outputs) internal pure {
        unchecked {
            for (uint256 i = 0; i < INPUT_SIZE; ++i) {
                verify(inputs[i], outputs[i]);
            }
        }
    }

    // Reverts if invalid
    function verify(Fixed18 input, Fixed18 output) internal pure {
        // Checks
        //       | output * output - input |
        //       --------------------------  < EPSILON
        //       |        output           |
        require(output.mul(output).distance(input).div(output).lt(EPSILON), "bad sqrt");
    }
}

