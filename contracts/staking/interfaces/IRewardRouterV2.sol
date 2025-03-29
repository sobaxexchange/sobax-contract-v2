// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardRouterV2 {
    function feeSblpTracker() external view returns (address);
    function stakedSblpTracker() external view returns (address);
}
