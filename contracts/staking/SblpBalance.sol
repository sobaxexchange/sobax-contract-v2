// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../core/interfaces/ISblpManager.sol";

contract SblpBalance {
    string private versionIdentifier = "ZM.0.0.4";
    using SafeMath for uint256;

    ISblpManager public sblpManager;
    address public stakedSblpTracker;

    mapping (address => mapping (address => uint256)) public allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        ISblpManager _sblpManager,
        address _stakedSblpTracker
    ) public {
        sblpManager = _sblpManager;
        stakedSblpTracker = _stakedSblpTracker;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) external returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "SblpBalance: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "SblpBalance: approve from the zero address");
        require(_spender != address(0), "SblpBalance: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "SblpBalance: transfer from the zero address");
        require(_recipient != address(0), "SblpBalance: transfer to the zero address");

        require(
            sblpManager.lastAddedAt(_sender).add(sblpManager.cooldownDuration()) <= block.timestamp,
            "SblpBalance: cooldown duration not yet passed"
        );

        IERC20(stakedSblpTracker).transferFrom(_sender, _recipient, _amount);
    }
}
