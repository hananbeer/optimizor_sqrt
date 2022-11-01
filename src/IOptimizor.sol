// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

uint256 constant EPOCH = 64;

interface IOptimizor {
    struct Submission {
        address sender;
        uint96 blockNumber;
    }

    error DoesNotSatisfyTolerance(uint256 input, uint256 output);


    // Commit errors
    error CodeAlreadySubmitted();
    error TooEarlyToChallenge();

    // Input filtering
    error InvalidRecipient();
    error CodeNotSubmitted();
    error NotPure();

    // Sadness
    error NotOptimizor();

    function extraDetails(uint256) external returns (address code, address solver, uint32 gas);

    /// Commit a `key` derived using
    /// `keccak256(abi.encode(sender, codehash, salt))`
    /// where
    /// - `sender`: the `msg.sender` for the call to `challenge(...)`,
    /// - `target`: the address of your solution contract,
    /// - `salt`: `uint256` secret number.
    function commit(bytes32 key) external;

    /// After committing and waiting for at least 256 blocks, challenge can be
    /// called to claim an Optimizor Club NFT, if it beats the previous solution
    /// in terms of runtime gas.
    ///
    /// @param id The unique identifier for the challenge.
    /// @param target The address of your solution contract.
    /// @param recipient The address that receives the Optimizor Club NFT.
    /// @param salt The secret number used for deriving the committed key.
    function challenge(uint256 id, address target, address recipient, uint256 salt) external;

    function balanceOf(address owner) external view returns (uint256);
}