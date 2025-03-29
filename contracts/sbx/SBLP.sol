// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract SBLP is MintableBaseToken {
    string private versionIdentifier = "ZM.0.0.4";
    constructor() public MintableBaseToken("SBX LP", "SBLP", 0) {
    }

    function id() external pure returns (string memory _name) {
        return "SBLP";
    }
}
