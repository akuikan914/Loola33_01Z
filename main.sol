// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Loola33 — archived beach telemetry from a kiosk nobody remembers.
/// The foam line drifts; the hoop remembers only torque ghosts.

contract Loola33MouseHulaField {
    error L33_BadAddr();
    error L33_Paused();
    error L33_NotOwner();
    error L33_NotGuard();
    error L33_BadEpoch();
    error L33_BadFee();
    error L33_BadCursor();
    error L33_DuplicateCommit();
    error L33_UnknownCommit();
    error L33_RevealWindow();
    error L33_BadReveal();
    error L33_ScoreCap();
    error L33_NoEth();
    error L33_BadSpin();
    error L33_Cooldown();
    error L33_BadgeMinted();
    error L33_TreasuryFail();
    error L33_NoRevealYet();
    event L33_Pause(bool indexed paused, uint64 at);
    event L33_FeeTuned(uint128 minWei, uint128 maxWei, uint64 at);
    event L33_Epoch(uint64 indexed epoch, bytes32 indexed ringSalt, uint64 at);
    event L33_Commit(address indexed who, bytes32 indexed commit, uint64 revealBy, uint64 at);
    event L33_Reveal(address indexed who, uint32 score, bytes32 indexed pathHash, uint64 at);
    event L33_Badge(address indexed who, uint8 tier, bytes32 indexed stamp, uint64 at);
    event L33_Withdraw(address indexed to, uint256 weiAmt, uint64 at);

    struct L33CommitEntry {
        bytes32 commit;
        uint64 revealBy;
        bool revealed;
    }

    struct L33RevealProof {
        uint32 score;
        uint32 cursorSteps;
        uint32 wobbleSeed;
        bytes32 pathHash;
    }

    address public immutable ADDRESS_A;
    address public immutable ADDRESS_B;
    address public immutable ADDRESS_C;
    address public immutable OWNER;

    bytes32 private constant _L33_SALT_0 = bytes32(hex"82787e22b14930e5726a1feefbaa96a586c0d07d3bc1b24f4f175fb3a7ea331f");
    bytes32 private constant _L33_SALT_1 = bytes32(hex"6ca0c5a3e6ab01d9d1d5c3f27b673fa6009ce3397738690dae4edafa4bcc6df2");
    bytes32 private constant _L33_SALT_2 = bytes32(hex"5a316b95a6129e2b04020eda5e59a23433833a841910f01589b7189aea020537");
    bytes32 private constant _L33_SALT_3 = bytes32(hex"c588a684a322fd0927cc3a87e3f1dc892974f28c627f1790412f2ebd30d19b63");
    bytes32 private constant _L33_SALT_4 = bytes32(hex"2057750bea141a3a4a72946386e51099ecb094265a2e4f46dc55c6e9ff739bb7");
    bytes32 private constant _L33_SALT_5 = bytes32(hex"15fa4737e74c867941dba09634602dd3e4345cfa035c3dfb23df85a87a6ad0fb");

    uint64 public epoch;
    bool public paused;
