// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IPriceFeed.sol";

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract PriceFeed is IPriceFeed {
    string private versionIdentifier = "ZM.0.1.0";
    uint80 public MAX_START_SAMPLE_NUMBER = 50;
    uint80 public startSampleNumber = 1;
    string public override description = "PricePythFeed";
    IPyth pyth;
    bytes32 public priceFeedId;
    address public override aggregator;

    address public gov;

    mapping (address => bool) public isAdmin;
    constructor(address pythContract, bytes32 _priceFeedId) {
        gov = msg.sender;
        isAdmin[msg.sender] = true;
        pyth = IPyth(pythContract);
        priceFeedId = _priceFeedId;
    }

    function setAdmin(address _account, bool _isAdmin) public {
        require(msg.sender == gov, "PriceFeed: forbidden");
        isAdmin[_account] = _isAdmin;
    }

    function latestAnswer() public override view returns (int256) {
        int256 price;

        PythStructs.Price memory pythPrice = pyth.getPrice(priceFeedId);
        price =  int256(int64(pythPrice.price));
        return price;
    }

    function latestRound() public override view returns (uint80) {
        return startSampleNumber;
    }

    function setStartSampleNumber(uint80 _startSampleNumber) public {
        require(msg.sender == gov, "PriceFeed: forbidden");
        require(_startSampleNumber > 0, "PriceFeed: invalid value specified for startSampleNumber");
        require(_startSampleNumber <= MAX_START_SAMPLE_NUMBER, "PriceFeed: invalid value specified for startSampleNumber");
        
        startSampleNumber = _startSampleNumber;

    }

    // returns roundId, answer, startedAt, updatedAt, answeredInRound
    function getRoundData(uint80 _currentNumber) public override view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        int256 price;
        PythStructs.Price memory pythPrice;
        
        try pyth.getPriceNoOlderThan(priceFeedId, uint256(_currentNumber)) returns (PythStructs.Price memory _pythPrice) {
            pythPrice = _pythPrice;
        } catch {
            pythPrice = pyth.getPrice(priceFeedId);
        }
        
        price =  int256(int64(pythPrice.price));

        return (0, price, 0, pythPrice.publishTime, 0);
    }
}
