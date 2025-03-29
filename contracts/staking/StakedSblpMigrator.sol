// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

import "../core/interfaces/ISblpManager.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IRewardTracker.sol";

import "../access/Governable.sol";

// provide a way to migrate staked SBLP tokens by unstaking from the sender
// and staking for the receiver
// meant for a one-time use for a specified sender
// requires the contract to be added as a handler for stakedSblpTracker and feeSblpTracker
contract StakedSblpMigrator is Governable {
    string private versionIdentifier = "ZM.0.0.4";
    using SafeMath for uint256;

    address public sender;
    address public sblp;
    address public stakedSblpTracker;
    address public feeSblpTracker;
    bool public isEnabled = true;

    constructor(
        address _sender,
        address _sblp,
        address _stakedSblpTracker,
        address _feeSblpTracker
    ) public {
        sender = _sender;
        sblp = _sblp;
        stakedSblpTracker = _stakedSblpTracker;
        feeSblpTracker = _feeSblpTracker;
    }

    function disable() external onlyGov {
        isEnabled = false;
    }

    function transfer(address _recipient, uint256 _amount) external onlyGov {
        _transfer(sender, _recipient, _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(isEnabled, "StakedSblpMigrator: not enabled");
        require(_sender != address(0), "StakedSblpMigrator: transfer from the zero address");
        require(_recipient != address(0), "StakedSblpMigrator: transfer to the zero address");

        IRewardTracker(stakedSblpTracker).unstakeForAccount(_sender, feeSblpTracker, _amount, _sender);
        IRewardTracker(feeSblpTracker).unstakeForAccount(_sender, sblp, _amount, _sender);

        IRewardTracker(feeSblpTracker).stakeForAccount(_sender, _recipient, sblp, _amount);
        IRewardTracker(stakedSblpTracker).stakeForAccount(_recipient, _recipient, feeSblpTracker, _amount);
    }
}
