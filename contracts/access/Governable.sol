// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    string private versionIdentifier = "ZM.0.0.4";
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}
