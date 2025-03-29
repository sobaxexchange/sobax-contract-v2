// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/ISblpManager.sol";
import "../access/Governable.sol";

contract RewardRouter is ReentrancyGuard, Governable {
    string private versionIdentifier = "ZM.0.0.4";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public isInitialized;

    address public weth;

    address public sbx;
    address public esSbx;
    address public bnSbx;

    address public sblp; // SBX Liquidity Provider token

    address public stakedSbxTracker;
    address public bonusSbxTracker;
    address public feeSbxTracker;

    address public stakedSblpTracker;
    address public feeSblpTracker;

    address public sblpManager;

    event StakeSbx(address account, uint256 amount);
    event UnstakeSbx(address account, uint256 amount);

    event StakeSblp(address account, uint256 amount);
    event UnstakeSblp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function initialize(
        address _weth,
        address _sbx,
        address _esSbx,
        address _bnSbx,
        address _sblp,
        address _stakedSbxTracker,
        address _bonusSbxTracker,
        address _feeSbxTracker,
        address _feeSblpTracker,
        address _stakedSblpTracker,
        address _sblpManager
    ) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        weth = _weth;

        sbx = _sbx;
        esSbx = _esSbx;
        bnSbx = _bnSbx;

        sblp = _sblp;

        stakedSbxTracker = _stakedSbxTracker;
        bonusSbxTracker = _bonusSbxTracker;
        feeSbxTracker = _feeSbxTracker;

        feeSblpTracker = _feeSblpTracker;
        stakedSblpTracker = _stakedSblpTracker;

        sblpManager = _sblpManager;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function batchStakeSbxForAccount(address[] memory _accounts, uint256[] memory _amounts) external nonReentrant onlyGov {
        address _sbx = sbx;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeSbx(msg.sender, _accounts[i], _sbx, _amounts[i]);
        }
    }

    function stakeSbxForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        _stakeSbx(msg.sender, _account, sbx, _amount);
    }

    function stakeSbx(uint256 _amount) external nonReentrant {
        _stakeSbx(msg.sender, msg.sender, sbx, _amount);
    }

    function stakeEsSbx(uint256 _amount) external nonReentrant {
        _stakeSbx(msg.sender, msg.sender, esSbx, _amount);
    }

    function unstakeSbx(uint256 _amount) external nonReentrant {
        _unstakeSbx(msg.sender, sbx, _amount);
    }

    function unstakeEsSbx(uint256 _amount) external nonReentrant {
        _unstakeSbx(msg.sender, esSbx, _amount);
    }

    function mintAndStakeSblp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minSblp) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 sblpAmount = ISblpManager(sblpManager).addLiquidityForAccount(account, account, _token, _amount, _minUsdg, _minSblp);
        IRewardTracker(feeSblpTracker).stakeForAccount(account, account, sblp, sblpAmount);
        IRewardTracker(stakedSblpTracker).stakeForAccount(account, account, feeSblpTracker, sblpAmount);

        emit StakeSblp(account, sblpAmount);

        return sblpAmount;
    }

    function mintAndStakeSblpETH(uint256 _minUsdg, uint256 _minSblp) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).approve(sblpManager, msg.value);

        address account = msg.sender;
        uint256 sblpAmount = ISblpManager(sblpManager).addLiquidityForAccount(address(this), account, weth, msg.value, _minUsdg, _minSblp);

        IRewardTracker(feeSblpTracker).stakeForAccount(account, account, sblp, sblpAmount);
        IRewardTracker(stakedSblpTracker).stakeForAccount(account, account, feeSblpTracker, sblpAmount);

        emit StakeSblp(account, sblpAmount);

        return sblpAmount;
    }

    function unstakeAndRedeemSblp(address _tokenOut, uint256 _sblpAmount, uint256 _minOut, address _receiver) external nonReentrant returns (uint256) {
        require(_sblpAmount > 0, "RewardRouter: invalid _sblpAmount");

        address account = msg.sender;
        IRewardTracker(stakedSblpTracker).unstakeForAccount(account, feeSblpTracker, _sblpAmount, account);
        IRewardTracker(feeSblpTracker).unstakeForAccount(account, sblp, _sblpAmount, account);
        uint256 amountOut = ISblpManager(sblpManager).removeLiquidityForAccount(account, _tokenOut, _sblpAmount, _minOut, _receiver);

        emit UnstakeSblp(account, _sblpAmount);

        return amountOut;
    }

    function unstakeAndRedeemSblpETH(uint256 _sblpAmount, uint256 _minOut, address payable _receiver) external nonReentrant returns (uint256) {
        require(_sblpAmount > 0, "RewardRouter: invalid _sblpAmount");

        address account = msg.sender;
        IRewardTracker(stakedSblpTracker).unstakeForAccount(account, feeSblpTracker, _sblpAmount, account);
        IRewardTracker(feeSblpTracker).unstakeForAccount(account, sblp, _sblpAmount, account);
        uint256 amountOut = ISblpManager(sblpManager).removeLiquidityForAccount(account, weth, _sblpAmount, _minOut, address(this));

        IWETH(weth).withdraw(amountOut);

        _receiver.sendValue(amountOut);

        emit UnstakeSblp(account, _sblpAmount);

        return amountOut;
    }

    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeSbxTracker).claimForAccount(account, account);
        IRewardTracker(feeSblpTracker).claimForAccount(account, account);

        IRewardTracker(stakedSbxTracker).claimForAccount(account, account);
        IRewardTracker(stakedSblpTracker).claimForAccount(account, account);
    }

    function claimEsSbx() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(stakedSbxTracker).claimForAccount(account, account);
        IRewardTracker(stakedSblpTracker).claimForAccount(account, account);
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeSbxTracker).claimForAccount(account, account);
        IRewardTracker(feeSblpTracker).claimForAccount(account, account);
    }

    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    function compoundForAccount(address _account) external nonReentrant onlyGov {
        _compound(_account);
    }

    function batchCompoundForAccounts(address[] memory _accounts) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    function _compound(address _account) private {
        _compoundSbx(_account);
        _compoundSblp(_account);
    }

    function _compoundSbx(address _account) private {
        uint256 esSbxAmount = IRewardTracker(stakedSbxTracker).claimForAccount(_account, _account);
        if (esSbxAmount > 0) {
            _stakeSbx(_account, _account, esSbx, esSbxAmount);
        }

        uint256 bnSbxAmount = IRewardTracker(bonusSbxTracker).claimForAccount(_account, _account);
        if (bnSbxAmount > 0) {
            IRewardTracker(feeSbxTracker).stakeForAccount(_account, _account, bnSbx, bnSbxAmount);
        }
    }

    function _compoundSblp(address _account) private {
        uint256 esSbxAmount = IRewardTracker(stakedSblpTracker).claimForAccount(_account, _account);
        if (esSbxAmount > 0) {
            _stakeSbx(_account, _account, esSbx, esSbxAmount);
        }
    }

    function _stakeSbx(address _fundingAccount, address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedSbxTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker(bonusSbxTracker).stakeForAccount(_account, _account, stakedSbxTracker, _amount);
        IRewardTracker(feeSbxTracker).stakeForAccount(_account, _account, bonusSbxTracker, _amount);

        emit StakeSbx(_account, _amount);
    }

    function _unstakeSbx(address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker(stakedSbxTracker).stakedAmounts(_account);

        IRewardTracker(feeSbxTracker).unstakeForAccount(_account, bonusSbxTracker, _amount, _account);
        IRewardTracker(bonusSbxTracker).unstakeForAccount(_account, stakedSbxTracker, _amount, _account);
        IRewardTracker(stakedSbxTracker).unstakeForAccount(_account, _token, _amount, _account);

        uint256 bnSbxAmount = IRewardTracker(bonusSbxTracker).claimForAccount(_account, _account);
        if (bnSbxAmount > 0) {
            IRewardTracker(feeSbxTracker).stakeForAccount(_account, _account, bnSbx, bnSbxAmount);
        }

        uint256 stakedBnSbx = IRewardTracker(feeSbxTracker).depositBalances(_account, bnSbx);
        if (stakedBnSbx > 0) {
            uint256 reductionAmount = stakedBnSbx.mul(_amount).div(balance);
            IRewardTracker(feeSbxTracker).unstakeForAccount(_account, bnSbx, reductionAmount, _account);
            IMintable(bnSbx).burn(_account, reductionAmount);
        }

        emit UnstakeSbx(_account, _amount);
    }
}
