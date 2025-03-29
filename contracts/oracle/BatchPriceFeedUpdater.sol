// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IPriceFeed {
    function setLatestAnswer(int256 _answer, uint256 _updatedAt) external;
}

contract BatchPriceFeedUpdater {
    string private versionIdentifier = "ZM.0.0.4";
    mapping(address => bool) public isAdmin;

    constructor() public {
        isAdmin[msg.sender] = true;
    }

    function addAdmin(address admin) external {
        require(isAdmin[msg.sender], "BatchPriceFeedUpdater: forbidden");
        isAdmin[admin] = true;
    }

    function batchSetLatestAnswer(
        address[] calldata priceFeeds,
        int256[] calldata answers,
        uint256 _updatedAt
    ) external {
        require(isAdmin[msg.sender], "BatchPriceFeedUpdater: forbidden");
        require(priceFeeds.length == answers.length, "Input arrays must have the same length");

        for (uint256 i = 0; i < priceFeeds.length; i++) {
            IPriceFeed(priceFeeds[i]).setLatestAnswer(answers[i], _updatedAt);
        }
    }
}
