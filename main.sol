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
    uint128 public minPlayWei;
    uint128 public maxPlayWei;
    uint32 public revealGraceBlocks;
    uint32 public playCooldownSecs;
    uint32 public scoreHardCap;
    mapping(address => uint64) private _lastPlayAt;
    mapping(address => L33CommitEntry) private _commitOf;
    mapping(address => uint8) public badgeTierOf;
    mapping(bytes32 => bool) private _usedCommit;
    mapping(address => bool) public hasRevealedOnce;

    modifier onlyOwner() {
        if (msg.sender != OWNER) revert L33_NotOwner();
        _;
    }

    modifier onlyGuard() {
        if (msg.sender != ADDRESS_B) revert L33_NotGuard();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert L33_Paused();
        _;
    }

    constructor(address addressA_, address addressB_, address addressC_) {
        if (addressA_ == address(0) || addressB_ == address(0) || addressC_ == address(0))
            revert L33_BadAddr();
        OWNER = msg.sender;
        ADDRESS_A = addressA_;
        ADDRESS_B = addressB_;
        ADDRESS_C = addressC_;
        epoch = 1;
        minPlayWei = 0;
        maxPlayWei = type(uint128).max / 4;
        revealGraceBlocks = 96;
        playCooldownSecs = 7;
        scoreHardCap = 1_000_000;
        emit L33_Epoch(epoch, keccak256(abi.encodePacked(_L33_SALT_0, _L33_SALT_1, block.chainid, uint256(uint160(address(this))))), uint64(block.timestamp));
    }

    receive() external payable {
        revert L33_NoEth();
    }

    fallback() external payable {
        revert L33_NoEth();
    }

    function _l33RingBiasV1(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 8;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 1) ^ (m << 2);
        return (z % 1000003) + 1;
    }

    function _l33RingBiasV2(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 9;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 2) ^ (m << 3);
        return (z % 1000003) + 2;
    }

    function _l33RingBiasV3(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 10;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 3) ^ (m << 4);
        return (z % 1000003) + 3;
    }

    function _l33RingBiasV4(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 11;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 4) ^ (m << 5);
        return (z % 1000003) + 4;
    }

    function _l33RingBiasV5(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 12;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 5) ^ (m << 6);
        return (z % 1000003) + 5;
    }

    function _l33RingBiasV6(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 13;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 6) ^ (m << 1);
        return (z % 1000003) + 6;
    }

    function _l33RingBiasV7(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 14;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 7) ^ (m << 2);
        return (z % 1000003) + 7;
    }

    function _l33RingBiasV8(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 15;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 8) ^ (m << 3);
        return (z % 1000003) + 8;
    }

    function _l33RingBiasV9(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 16;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 0) ^ (m << 4);
        return (z % 1000003) + 9;
    }

    function _l33RingBiasV10(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 17;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 1) ^ (m << 5);
        return (z % 1000003) + 10;
    }

    function _l33RingBiasV11(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 7;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 2) ^ (m << 6);
        return (z % 1000003) + 11;
    }

    function _l33RingBiasV12(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 8;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 3) ^ (m << 1);
        return (z % 1000003) + 12;
    }

    function _l33RingBiasV13(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 9;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 4) ^ (m << 2);
        return (z % 1000003) + 13;
    }

    function _l33RingBiasV14(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 10;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 5) ^ (m << 3);
        return (z % 1000003) + 14;
    }

    function _l33RingBiasV15(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 11;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 6) ^ (m << 4);
        return (z % 1000003) + 15;
    }

    function _l33RingBiasV16(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 12;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 7) ^ (m << 5);
        return (z % 1000003) + 16;
    }

    function _l33RingBiasV17(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 13;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 8) ^ (m << 6);
        return (z % 1000003) + 17;
    }

    function _l33RingBiasV18(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 14;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 0) ^ (m << 1);
        return (z % 1000003) + 18;
    }

    function _l33RingBiasV19(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 15;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 1) ^ (m << 2);
        return (z % 1000003) + 19;
    }

    function _l33RingBiasV20(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 16;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 2) ^ (m << 3);
        return (z % 1000003) + 20;
    }

    function _l33RingBiasV21(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 17;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 3) ^ (m << 4);
        return (z % 1000003) + 21;
    }

    function _l33RingBiasV22(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 7;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 4) ^ (m << 5);
        return (z % 1000003) + 22;
    }

    function _l33RingBiasV23(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 8;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 5) ^ (m << 6);
        return (z % 1000003) + 23;
    }

    function _l33RingBiasV24(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 9;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 6) ^ (m << 1);
        return (z % 1000003) + 24;
    }

    function _l33RingBiasV25(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 10;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 7) ^ (m << 2);
        return (z % 1000003) + 25;
    }

    function _l33RingBiasV26(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 11;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 8) ^ (m << 3);
        return (z % 1000003) + 26;
    }

    function _l33RingBiasV27(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 12;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 0) ^ (m << 4);
        return (z % 1000003) + 27;
    }

    function _l33RingBiasV28(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 13;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 1) ^ (m << 5);
        return (z % 1000003) + 28;
    }

    function _l33RingBiasV29(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 14;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 2) ^ (m << 6);
        return (z % 1000003) + 29;
    }

    function _l33RingBiasV30(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 15;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 3) ^ (m << 1);
        return (z % 1000003) + 30;
    }

    function _l33RingBiasV31(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 16;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 4) ^ (m << 2);
        return (z % 1000003) + 31;
    }

    function _l33RingBiasV32(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 17;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 5) ^ (m << 3);
        return (z % 1000003) + 32;
    }

    function _l33RingBiasV33(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 7;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 6) ^ (m << 4);
        return (z % 1000003) + 33;
    }

    function _l33RingBiasV34(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 8;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 7) ^ (m << 5);
        return (z % 1000003) + 34;
    }

    function _l33RingBiasV35(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 9;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 8) ^ (m << 6);
        return (z % 1000003) + 35;
    }

    function _l33RingBiasV36(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 10;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 0) ^ (m << 1);
        return (z % 1000003) + 36;
    }

    function _l33RingBiasV37(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 11;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 1) ^ (m << 2);
        return (z % 1000003) + 37;
    }

    function _l33RingBiasV38(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 12;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 2) ^ (m << 3);
        return (z % 1000003) + 38;
    }

    function _l33RingBiasV39(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 13;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 3) ^ (m << 4);
        return (z % 1000003) + 39;
    }

    function _l33RingBiasV40(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 14;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 4) ^ (m << 5);
        return (z % 1000003) + 40;
    }

    function _l33RingBiasV41(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 15;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 5) ^ (m << 6);
        return (z % 1000003) + 41;
    }

    function _l33RingBiasV42(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 16;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 6) ^ (m << 1);
        return (z % 1000003) + 42;
    }

    function _l33RingBiasV43(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 17;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 7) ^ (m << 2);
        return (z % 1000003) + 43;
    }

    function _l33RingBiasV44(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 7;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 8) ^ (m << 3);
        return (z % 1000003) + 44;
    }

    function _l33RingBiasV45(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 8;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 0) ^ (m << 4);
        return (z % 1000003) + 45;
    }

    function _l33RingBiasV46(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 9;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 1) ^ (m << 5);
        return (z % 1000003) + 46;
    }

    function _l33RingBiasV47(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 10;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 2) ^ (m << 6);
        return (z % 1000003) + 47;
    }

    function _l33RingBiasV48(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 11;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 3) ^ (m << 1);
        return (z % 1000003) + 48;
    }

    function _l33RingBiasV49(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 12;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 4) ^ (m << 2);
        return (z % 1000003) + 49;
    }

    function _l33RingBiasV50(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 13;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 5) ^ (m << 3);
        return (z % 1000003) + 50;
    }

    function _l33RingBiasV51(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 14;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 6) ^ (m << 4);
        return (z % 1000003) + 51;
    }

    function _l33RingBiasV52(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 15;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 7) ^ (m << 5);
        return (z % 1000003) + 52;
    }

    function _l33RingBiasV53(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 16;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 8) ^ (m << 6);
        return (z % 1000003) + 53;
    }

    function _l33RingBiasV54(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 17;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 0) ^ (m << 1);
        return (z % 1000003) + 54;
    }

    function _l33RingBiasV55(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 7;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 1) ^ (m << 2);
        return (z % 1000003) + 55;
    }

    function _l33RingBiasV56(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 8;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 2) ^ (m << 3);
        return (z % 1000003) + 56;
    }

    function _l33RingBiasV57(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 9;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 3) ^ (m << 4);
        return (z % 1000003) + 57;
    }

    function _l33RingBiasV58(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 10;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 4) ^ (m << 5);
        return (z % 1000003) + 58;
    }

    function _l33RingBiasV59(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 11;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 5) ^ (m << 6);
        return (z % 1000003) + 59;
    }

    function _l33RingBiasV60(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 12;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 6) ^ (m << 1);
        return (z % 1000003) + 60;
    }

    function _l33RingBiasV61(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 13;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 7) ^ (m << 2);
        return (z % 1000003) + 61;
    }

    function _l33RingBiasV62(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 14;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 8) ^ (m << 3);
        return (z % 1000003) + 62;
    }

    function _l33RingBiasV63(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 15;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 0) ^ (m << 4);
        return (z % 1000003) + 63;
    }

    function _l33RingBiasV64(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 16;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 1) ^ (m << 5);
        return (z % 1000003) + 64;
    }

    function _l33RingBiasV65(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 17;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 2) ^ (m << 6);
        return (z % 1000003) + 65;
    }

    function _l33RingBiasV66(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 7;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 3) ^ (m << 1);
        return (z % 1000003) + 66;
    }

    function _l33RingBiasV67(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 8;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 4) ^ (m << 2);
        return (z % 1000003) + 67;
    }

    function _l33RingBiasV68(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 9;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 5) ^ (m << 3);
        return (z % 1000003) + 68;
    }

    function _l33RingBiasV69(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 10;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 6) ^ (m << 4);
        return (z % 1000003) + 69;
    }

    function _l33RingBiasV70(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 11;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 7) ^ (m << 5);
        return (z % 1000003) + 70;
    }

    function _l33RingBiasV71(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 12;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 8) ^ (m << 6);
        return (z % 1000003) + 71;
    }

    function _l33RingBiasV72(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 13;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 0) ^ (m << 1);
        return (z % 1000003) + 72;
    }

    function _l33RingBiasV73(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 14;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 1) ^ (m << 2);
        return (z % 1000003) + 73;
    }

    function _l33RingBiasV74(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 15;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 2) ^ (m << 3);
        return (z % 1000003) + 74;
    }

    function _l33RingBiasV75(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 16;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 3) ^ (m << 4);
        return (z % 1000003) + 75;
    }

    function _l33RingBiasV76(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 17;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 4) ^ (m << 5);
        return (z % 1000003) + 76;
    }

    function _l33RingBiasV77(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 7;
        uint256 m = (t * 15) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 5) ^ (m << 6);
        return (z % 1000003) + 77;
    }

    function _l33RingBiasV78(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 8;
        uint256 m = (t * 16) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 6) ^ (m << 1);
        return (z % 1000003) + 78;
    }

    function _l33RingBiasV79(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 9;
        uint256 m = (t * 17) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 7) ^ (m << 2);
        return (z % 1000003) + 79;
    }

    function _l33RingBiasV80(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 10;
        uint256 m = (t * 13) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 8) ^ (m << 3);
        return (z % 1000003) + 80;
    }

    function _l33RingBiasV81(uint256 x, uint256 y, uint256 saltN) internal pure returns (uint256) {
        uint256 t = (x ^ y) + saltN * 11;
        uint256 m = (t * 14) % 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 z = (m >> 0) ^ (m << 4);
        return (z % 1000003) + 81;
    }

    function _l33CursorWarpV1(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 4;
        acc ^= uint256(steps) * 12;
        acc ^= k0 * 6;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV2(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 5;
        acc ^= uint256(steps) * 13;
        acc ^= k0 * 7;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV3(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 6;
        acc ^= uint256(steps) * 14;
        acc ^= k0 * 8;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV4(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 7;
        acc ^= uint256(steps) * 15;
        acc ^= k0 * 9;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV5(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 8;
        acc ^= uint256(steps) * 16;
        acc ^= k0 * 10;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV6(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 9;
        acc ^= uint256(steps) * 17;
        acc ^= k0 * 11;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV7(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 10;
        acc ^= uint256(steps) * 18;
        acc ^= k0 * 12;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV8(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 11;
        acc ^= uint256(steps) * 19;
        acc ^= k0 * 13;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV9(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 12;
        acc ^= uint256(steps) * 20;
        acc ^= k0 * 14;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV10(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 13;
        acc ^= uint256(steps) * 21;
        acc ^= k0 * 15;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV11(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 14;
        acc ^= uint256(steps) * 22;
        acc ^= k0 * 16;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV12(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 15;
        acc ^= uint256(steps) * 23;
        acc ^= k0 * 17;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV13(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 16;
        acc ^= uint256(steps) * 24;
        acc ^= k0 * 18;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV14(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 17;
        acc ^= uint256(steps) * 25;
        acc ^= k0 * 19;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV15(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 18;
        acc ^= uint256(steps) * 26;
        acc ^= k0 * 20;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV16(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 19;
        acc ^= uint256(steps) * 27;
        acc ^= k0 * 21;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV17(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 3;
        acc ^= uint256(steps) * 28;
        acc ^= k0 * 22;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV18(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 4;
        acc ^= uint256(steps) * 29;
        acc ^= k0 * 23;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV19(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 5;
        acc ^= uint256(steps) * 30;
        acc ^= k0 * 5;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV20(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 6;
        acc ^= uint256(steps) * 31;
        acc ^= k0 * 6;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV21(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 7;
        acc ^= uint256(steps) * 32;
        acc ^= k0 * 7;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV22(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 8;
        acc ^= uint256(steps) * 33;
        acc ^= k0 * 8;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV23(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 9;
        acc ^= uint256(steps) * 11;
        acc ^= k0 * 9;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV24(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 10;
        acc ^= uint256(steps) * 12;
        acc ^= k0 * 10;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV25(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 11;
        acc ^= uint256(steps) * 13;
        acc ^= k0 * 11;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV26(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 12;
        acc ^= uint256(steps) * 14;
        acc ^= k0 * 12;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV27(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 13;
        acc ^= uint256(steps) * 15;
        acc ^= k0 * 13;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV28(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 14;
        acc ^= uint256(steps) * 16;
        acc ^= k0 * 14;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV29(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 15;
        acc ^= uint256(steps) * 17;
        acc ^= k0 * 15;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV30(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 16;
        acc ^= uint256(steps) * 18;
        acc ^= k0 * 16;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV31(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 17;
        acc ^= uint256(steps) * 19;
        acc ^= k0 * 17;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV32(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 18;
        acc ^= uint256(steps) * 20;
        acc ^= k0 * 18;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV33(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 19;
        acc ^= uint256(steps) * 21;
        acc ^= k0 * 19;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV34(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 3;
        acc ^= uint256(steps) * 22;
        acc ^= k0 * 20;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV35(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 4;
        acc ^= uint256(steps) * 23;
        acc ^= k0 * 21;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV36(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 5;
        acc ^= uint256(steps) * 24;
        acc ^= k0 * 22;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV37(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 6;
        acc ^= uint256(steps) * 25;
        acc ^= k0 * 23;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV38(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 7;
        acc ^= uint256(steps) * 26;
        acc ^= k0 * 5;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV39(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 8;
        acc ^= uint256(steps) * 27;
        acc ^= k0 * 6;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV40(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 9;
        acc ^= uint256(steps) * 28;
        acc ^= k0 * 7;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV41(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 10;
        acc ^= uint256(steps) * 29;
        acc ^= k0 * 8;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV42(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 11;
        acc ^= uint256(steps) * 30;
        acc ^= k0 * 9;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV43(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 12;
        acc ^= uint256(steps) * 31;
        acc ^= k0 * 10;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV44(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 13;
        acc ^= uint256(steps) * 32;
        acc ^= k0 * 11;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV45(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 14;
        acc ^= uint256(steps) * 33;
        acc ^= k0 * 12;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV46(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 15;
        acc ^= uint256(steps) * 11;
        acc ^= k0 * 13;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV47(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 16;
        acc ^= uint256(steps) * 12;
        acc ^= k0 * 14;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV48(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 17;
        acc ^= uint256(steps) * 13;
        acc ^= k0 * 15;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV49(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 18;
        acc ^= uint256(steps) * 14;
        acc ^= k0 * 16;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV50(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 19;
        acc ^= uint256(steps) * 15;
        acc ^= k0 * 17;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV51(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 3;
        acc ^= uint256(steps) * 16;
        acc ^= k0 * 18;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV52(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 4;
        acc ^= uint256(steps) * 17;
        acc ^= k0 * 19;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV53(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 5;
        acc ^= uint256(steps) * 18;
        acc ^= k0 * 20;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV54(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 6;
        acc ^= uint256(steps) * 19;
        acc ^= k0 * 21;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV55(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 7;
        acc ^= uint256(steps) * 20;
        acc ^= k0 * 22;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV56(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 8;
        acc ^= uint256(steps) * 21;
        acc ^= k0 * 23;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV57(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 9;
        acc ^= uint256(steps) * 22;
        acc ^= k0 * 5;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV58(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 10;
        acc ^= uint256(steps) * 23;
        acc ^= k0 * 6;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV59(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 11;
        acc ^= uint256(steps) * 24;
        acc ^= k0 * 7;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV60(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 12;
        acc ^= uint256(steps) * 25;
        acc ^= k0 * 8;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV61(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 13;
        acc ^= uint256(steps) * 26;
        acc ^= k0 * 9;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV62(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 14;
        acc ^= uint256(steps) * 27;
        acc ^= k0 * 10;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV63(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 15;
        acc ^= uint256(steps) * 28;
        acc ^= k0 * 11;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV64(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 16;
        acc ^= uint256(steps) * 29;
        acc ^= k0 * 12;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV65(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 17;
        acc ^= uint256(steps) * 30;
        acc ^= k0 * 13;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV66(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 18;
        acc ^= uint256(steps) * 31;
        acc ^= k0 * 14;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV67(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 19;
        acc ^= uint256(steps) * 32;
        acc ^= k0 * 15;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV68(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 3;
        acc ^= uint256(steps) * 33;
        acc ^= k0 * 16;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV69(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 4;
        acc ^= uint256(steps) * 11;
        acc ^= k0 * 17;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV70(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 5;
        acc ^= uint256(steps) * 12;
        acc ^= k0 * 18;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV71(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 6;
        acc ^= uint256(steps) * 13;
        acc ^= k0 * 19;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV72(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 7;
        acc ^= uint256(steps) * 14;
        acc ^= k0 * 20;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV73(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 8;
        acc ^= uint256(steps) * 15;
        acc ^= k0 * 21;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV74(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 9;
        acc ^= uint256(steps) * 16;
        acc ^= k0 * 22;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV75(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 10;
        acc ^= uint256(steps) * 17;
        acc ^= k0 * 23;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV76(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 11;
        acc ^= uint256(steps) * 18;
        acc ^= k0 * 5;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV77(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 12;
        acc ^= uint256(steps) * 19;
        acc ^= k0 * 6;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV78(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 13;
        acc ^= uint256(steps) * 20;
        acc ^= k0 * 7;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV79(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 14;
        acc ^= uint256(steps) * 21;
        acc ^= k0 * 8;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33CursorWarpV80(uint32 steps, uint32 seed, uint256 k0) internal pure returns (uint32) {
        uint256 acc = uint256(seed) * 15;
        acc ^= uint256(steps) * 22;
        acc ^= k0 * 9;
        acc = (acc * 1103515245 + 12345) & 0x7fffffff;
        return uint32(acc % 0xffffffff);
    }

    function _l33HulaTorqueV1(uint32 w0, uint32 w1, uint32 w2) internal pure returns (uint32) {
        uint256 t = uint256(w0) * 4 + uint256(w1) * 8 + uint256(w2) * 12;
        t = (t ^ (t >> 17)) * 0xed5ad4bb;
        t ^= (t >> 11);
        return uint32(t % 1000001);
    }

    function _l33HulaTorqueV2(uint32 w0, uint32 w1, uint32 w2) internal pure returns (uint32) {
        uint256 t = uint256(w0) * 5 + uint256(w1) * 9 + uint256(w2) * 13;
        t = (t ^ (t >> 17)) * 0xed5ad4bb;
        t ^= (t >> 11);
        return uint32(t % 1000001);
    }

    function _l33HulaTorqueV3(uint32 w0, uint32 w1, uint32 w2) internal pure returns (uint32) {
        uint256 t = uint256(w0) * 6 + uint256(w1) * 10 + uint256(w2) * 14;
        t = (t ^ (t >> 17)) * 0xed5ad4bb;
        t ^= (t >> 11);
        return uint32(t % 1000001);
    }

    function _l33HulaTorqueV4(uint32 w0, uint32 w1, uint32 w2) internal pure returns (uint32) {
        uint256 t = uint256(w0) * 7 + uint256(w1) * 11 + uint256(w2) * 15;
        t = (t ^ (t >> 17)) * 0xed5ad4bb;
        t ^= (t >> 11);
        return uint32(t % 1000001);
    }

    function _l33HulaTorqueV5(uint32 w0, uint32 w1, uint32 w2) internal pure returns (uint32) {
        uint256 t = uint256(w0) * 8 + uint256(w1) * 12 + uint256(w2) * 16;
        t = (t ^ (t >> 17)) * 0xed5ad4bb;
        t ^= (t >> 11);
        return uint32(t % 1000001);
    }

    function _l33HulaTorqueV6(uint32 w0, uint32 w1, uint32 w2) internal pure returns (uint32) {
        uint256 t = uint256(w0) * 9 + uint256(w1) * 13 + uint256(w2) * 17;
        t = (t ^ (t >> 17)) * 0xed5ad4bb;
        t ^= (t >> 11);
        return uint32(t % 1000001);
    }

    function _l33HulaTorqueV7(uint32 w0, uint32 w1, uint32 w2) internal pure returns (uint32) {
        uint256 t = uint256(w0) * 10 + uint256(w1) * 14 + uint256(w2) * 18;
        t = (t ^ (t >> 17)) * 0xed5ad4bb;
        t ^= (t >> 11);
        return uint32(t % 1000001);
    }

    function _l33HulaTorqueV8(uint32 w0, uint32 w1, uint32 w2) internal pure returns (uint32) {
        uint256 t = uint256(w0) * 11 + uint256(w1) * 15 + uint256(w2) * 19;
        t = (t ^ (t >> 17)) * 0xed5ad4bb;
        t ^= (t >> 11);
        return uint32(t % 1000001);
    }

    function _l33HulaTorqueV9(uint32 w0, uint32 w1, uint32 w2) internal pure returns (uint32) {
        uint256 t = uint256(w0) * 12 + uint256(w1) * 16 + uint256(w2) * 20;
        t = (t ^ (t >> 17)) * 0xed5ad4bb;
        t ^= (t >> 11);
        return uint32(t % 1000001);
    }

