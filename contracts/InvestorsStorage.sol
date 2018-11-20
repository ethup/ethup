pragma solidity 0.4.24;

import "./Accessibility.sol";
import "./SafeMath.sol";

contract InvestorsStorage is Accessibility {
    using SafeMath for uint;

    struct Dividends {
        uint value;     //paid
        uint limit;
        uint deferred;  //not paid yet
    }

    struct Investor {
        uint investment;
        uint paymentTime;
        Dividends dividends;
    }
    uint public size;

    mapping (address => Investor) private investors;

    function isInvestor(address addr) public view returns (bool) {
        return investors[addr].investment > 0;
    }

    function investorInfo(address addr) public view returns(uint investment, uint paymentTime, uint value, uint limit, uint deferred) {
        investment = investors[addr].investment;
        paymentTime = investors[addr].paymentTime;
        value = investors[addr].dividends.value;
        limit = investors[addr].dividends.limit;
        deferred = investors[addr].dividends.deferred;
    }

    function newInvestor(address addr, uint investment, uint paymentTime, uint dividendsLimit) public onlyOwner returns (bool) {
        Investor storage inv = investors[addr];
        if (inv.investment != 0 || investment == 0) {
            return false;
        }
        inv.investment = investment;
        inv.paymentTime = paymentTime;
        inv.dividends.limit = dividendsLimit;
        size++;
        return true;
    }

    function addInvestment(address addr, uint investment) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].investment = investors[addr].investment.add(investment);
        return true;
    }

    function setPaymentTime(address addr, uint paymentTime) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].paymentTime = paymentTime;
        return true;
    }

    function addDeferredDividends(address addr, uint dividends) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
          return false;
        }
        investors[addr].dividends.deferred = investors[addr].dividends.deferred.add(dividends);
        return true;
    }

    function addDividends(address addr, uint dividends) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
          return false;
        }
        if (investors[addr].dividends.value + dividends > investors[addr].dividends.limit) {
            investors[addr].dividends.value = investors[addr].dividends.limit;
        } else {
            investors[addr].dividends.value = investors[addr].dividends.value.add(dividends);
        }
        return true;
    }

    function setNewInvestment(address addr, uint investment, uint limit) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].investment = investment;
        investors[addr].dividends.limit = limit;
        // reset payment dividends
        investors[addr].dividends.value = 0;
        investors[addr].dividends.deferred = 0;

        return true;
    }

    function addDividendsLimit(address addr, uint limit) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].dividends.limit = investors[addr].dividends.limit.add(limit);

        return true;
    }
}
