// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../Vault.sol";

contract VaultTest is Vault {
    string private versionIdentifier = "ZM.0.0.4";
    function increaseGlobalShortSize(address token, uint256 amount) external {
        _increaseGlobalShortSize(token, amount);
    }
}
