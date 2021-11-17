// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // wei olarak depolar
    function fund() public payable {
        uint256 minimumUSD = 50 * (10**18); //wei olarak depoladığımız için 50 * 10^18 yapıyoruz

        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to donate at least 50$ dollars worth of ETH"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // fiyatı gwei olarak döndürür
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10**10);
    }

    // değerin küsuratlarından kurtulup 1 eth kaç dolar onu anlık döndürür
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10**18);
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        //minimum USD
        uint256 minimumUSD = 50 * 10**20;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner); // eğer bu talepte bulunan adress ile parayı yatıran eşleşmiyorsa işlemi revert eder
        _; // eğer bu eşleşme True döndürürse geriye kalan kodu çalıştırır
    }

    // sözleşmeye yatırılmış bütün parayı çeker (sözleşmeyle kim iletişime geçiyorsa(owner) onun cüzdanına çeker)
    function withdraw() public payable {
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; // bağışçıların balance'larını sıfırlar
        }
        funders = new address[](0); // bağışçı listesini sıfırlar
    }
}
