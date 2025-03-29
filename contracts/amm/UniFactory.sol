// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract UniFactory {
    string private versionIdentifier = "ZM.0.0.4";
    mapping(address => mapping(address => mapping(uint24 => address))) public getPool;
}
