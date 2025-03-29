// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract EsSBX is MintableBaseToken {
    string private versionIdentifier = "ZM.0.0.4";
    constructor() public MintableBaseToken("Escrowed SBX", "esSBX", 0) {
    }

    function id() external pure returns (string memory _name) {
        return "esSBX";
    }
}
