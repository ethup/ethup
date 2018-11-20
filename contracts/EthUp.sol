pragma solidity 0.4.25;

// solium-disable security/no-block-members

/**
 * @title Autonomus smart fund
 * @author ethup — https://ethup.io
 */

import "./InvestorsStorage.sol";
import "./SafeMath.sol";
import "./Percent.sol";
import "./Accessibility.sol";
import "./Zero.sol";
import "./ToAddress.sol";


contract EthUp is Accessibility {
    using Percent for Percent.percent;
    using SafeMath for uint;
    using Zero for *;
    using ToAddress for *;

    // investors storage - iterable map;
    InvestorsStorage private m_investors;
    mapping(address => bool) private m_referrals;

    // automatically generates getters
    address public advertisingAddress;
    address public adminsAddress;
    uint public investmentsNumber;
    uint public constant MIN_INVESTMENT = 10 finney; // 0.01 eth
    uint public constant MAX_INVESTMENT = 50 ether;
    uint public constant MAX_BALANCE = 1e5 ether; // 100 000 eth

    // percents
    Percent.percent private m_1_percent = Percent.percent(1, 100);          //  1/100   *100% = 1%
    Percent.percent private m_1_5_percent = Percent.percent(15, 1000);      //  15/1000 *100% = 1.5%
    Percent.percent private m_2_percent = Percent.percent(2, 100);          //  2/100   *100% = 2%
    Percent.percent private m_2_5_percent = Percent.percent(25, 1000);      //  25/1000 *100% = 2.5%
    Percent.percent private m_3_percent = Percent.percent(3, 100);          //  3/100   *100% = 3%
    Percent.percent private m_3_5_percent = Percent.percent(35, 1000);      //  35/1000 *100% = 3.5%
    Percent.percent private m_4_percent = Percent.percent(4, 100);          //  4/100   *100% = 4%

    Percent.percent private m_refPercent = Percent.percent(5, 100);         //  5/100   *100% = 5%
    Percent.percent private m_adminsPercent = Percent.percent(5, 100);      //  5/100   *100% = 5%
    Percent.percent private m_advertisingPercent = Percent.percent(1, 10);  //  1/10    *100% = 10%

    Percent.percent private m_maxDepositPercent = Percent.percent(15, 10);  //  15/10   *100% = 150%
    Percent.percent private m_reinvestPercent = Percent.percent(1, 10);     //  10/100  *100% = 10%

    // more events for easy read from blockchain
    event LogSendExcessOfEther(address indexed addr, uint when, uint value, uint investment, uint excess);
    event LogNewInvestor(address indexed addr, uint when);
    event LogNewInvestment(address indexed addr, uint when, uint investment, uint value);
    event LogNewReferral(address indexed addr, address indexed referrerAddr, uint when, uint refBonus);
    event LogReinvest(address indexed addr, uint when, uint investment);
    event LogPayDividends(address indexed addr, uint when, uint value);
    event LogPayReferrerBonus(address indexed addr, uint when, uint value);
    event LogBalanceChanged(uint when, uint balance);
    event LogDisown(uint when);

    modifier balanceChanged() {
        _;
        emit LogBalanceChanged(now, address(this).balance);
    }

    modifier notFromContract() {
        require(msg.sender.isNotContract(), "only externally accounts");
        _;
    }

    constructor() public {
        adminsAddress = msg.sender;
        advertisingAddress = msg.sender;

        m_investors = new InvestorsStorage();
        investmentsNumber = 0;
    }

    function() public payable {
        // investor get him dividends
        if (msg.value.isZero()) {
            getMyDividends();
            return;
        }

        // sender do invest
        doInvest(msg.data.toAddress());
    }

    function doDisown() public onlyOwner {
        disown();
        emit LogDisown(now);
    }

    function investorsNumber() public view returns(uint) {
        return m_investors.size();
    }

    function balanceETH() public view returns(uint) {
        return address(this).balance;
    }

    function percent1() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_1_percent.num, m_1_percent.den);
    }

    function percent1_5() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_1_5_percent.num, m_1_5_percent.den);
    }

    function percent2() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_2_percent.num, m_2_percent.den);
    }

    function percent2_5() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_2_5_percent.num, m_2_5_percent.den);
    }

    function percent3() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_3_percent.num, m_3_percent.den);
    }

    function percent3_5() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_3_5_percent.num, m_3_5_percent.den);
    }

    function percent4() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_4_percent.num, m_4_percent.den);
    }

    function advertisingPercent() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_advertisingPercent.num, m_advertisingPercent.den);
    }

    function adminsPercent() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_adminsPercent.num, m_adminsPercent.den);
    }

    function maxDepositPercent() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_maxDepositPercent.num, m_maxDepositPercent.den);
    }

    function investorInfo(
        address investorAddr
    )
        public
        view
        returns (
            uint investment,
            uint paymentTime,
            uint dividends,
            uint dividendsLimit,
            uint dividendsDeferred,
            bool isReferral
        )
    {
        (
            investment,
            paymentTime,
            dividends,
            dividendsLimit,
            dividendsDeferred
        ) = m_investors.investorInfo(investorAddr);

        isReferral = m_referrals[investorAddr];
    }

    function getInvestorDividendsAtNow(
        address investorAddr
    )
        public
        view
        returns (
            uint dividends
        )
    {
        dividends = calcDividends(investorAddr);
    }

    function getDailyPercentAtNow(
        address investorAddr
    )
        public
        view
        returns (
            uint numerator,
            uint denominator
        )
    {
        InvestorsStorage.Investor memory investor = getMemInvestor(investorAddr);

        Percent.percent memory p = getDailyPercent(investor.investment);
        (numerator, denominator) = (p.num, p.den);
    }

    function getRefBonusPercentAtNow() public view returns(uint numerator, uint denominator) {
        Percent.percent memory p = getRefBonusPercent();
        (numerator, denominator) = (p.num, p.den);
    }

    function getMyDividends() public notFromContract balanceChanged {
        // calculate dividends
        uint dividends = calcDividends(msg.sender);
        require(dividends.notZero(), "cannot to pay zero dividends");

        // update investor payment timestamp
        assert(m_investors.setPaymentTime(msg.sender, now));

        // check enough eth
        if (address(this).balance < dividends) {
            dividends = address(this).balance;
        }

        // update payouts dividends
        assert(m_investors.addDividends(msg.sender, dividends));

        // transfer dividends to investor
        msg.sender.transfer(dividends);
        emit LogPayDividends(msg.sender, now, dividends);
    }

    function doInvest(address referrerAddr) public payable notFromContract balanceChanged {
        uint investment = msg.value;
        uint receivedEther = msg.value;

        require(investment >= MIN_INVESTMENT, "investment must be >= MIN_INVESTMENT");
        require(address(this).balance + investment <= MAX_BALANCE, "the contract eth balance limit");

        // send excess of ether if needed
        if (receivedEther > MAX_INVESTMENT) {
            uint excess = receivedEther - MAX_INVESTMENT;
            investment = MAX_INVESTMENT;
            msg.sender.transfer(excess);
            emit LogSendExcessOfEther(msg.sender, now, receivedEther, investment, excess);
        }

        // commission
        uint advertisingCommission = m_advertisingPercent.mul(investment);
        uint adminsCommission = m_adminsPercent.mul(investment);

        bool senderIsInvestor = m_investors.isInvestor(msg.sender);

        // ref system works only once and only on first invest
        if (referrerAddr.notZero() &&
            !senderIsInvestor &&
            !m_referrals[msg.sender] &&
            referrerAddr != msg.sender &&
            m_investors.isInvestor(referrerAddr)) {

            // add referral bonus to investor`s and referral`s investments
            uint refBonus = getRefBonusPercent().mmul(investment);
            assert(m_investors.addInvestment(referrerAddr, refBonus)); // add referrer bonus
            investment = investment.add(refBonus);                     // add referral bonus
            m_referrals[msg.sender] = true;
            emit LogNewReferral(msg.sender, referrerAddr, now, refBonus);
        }

        // Dividends cannot be greater then 150% from investor investment
        uint maxDividends = getMaxDepositPercent().mmul(investment);

        if (senderIsInvestor) {
            // check for reinvest
            InvestorsStorage.Investor memory investor = getMemInvestor(msg.sender);
            if (investor.dividends.value == investor.dividends.limit) {
                uint reinvestBonus = getReinvestBonusPercent().mmul(investment);
                investment = investment.add(reinvestBonus);
                maxDividends = getMaxDepositPercent().mmul(investment);
                // reinvest
                assert(m_investors.setNewInvestment(msg.sender, investment, maxDividends));
                emit LogReinvest(msg.sender, now, investment);
            } else {
                // prevent burning dividends
                uint dividends = calcDividends(msg.sender);
                if (dividends.notZero()) {
                    assert(m_investors.addDeferredDividends(msg.sender, dividends));
                }
                // update existing investor investment
                assert(m_investors.addInvestment(msg.sender, investment));
                assert(m_investors.addDividendsLimit(msg.sender, maxDividends));
            }
            assert(m_investors.setPaymentTime(msg.sender, now));
        } else {
            // create new investor
            assert(m_investors.newInvestor(msg.sender, investment, now, maxDividends));
            emit LogNewInvestor(msg.sender, now);
        }

        investmentsNumber++;
        advertisingAddress.transfer(advertisingCommission);
        adminsAddress.transfer(adminsCommission);
        emit LogNewInvestment(msg.sender, now, investment, receivedEther);
    }

    function setAdvertisingAddress(address addr) public onlyOwner {
        addr.requireNotZero();
        advertisingAddress = addr;
    }

    function setAdminsAddress(address addr) public onlyOwner {
        addr.requireNotZero();
        adminsAddress = addr;
    }

    function getMemInvestor(
        address investorAddr
    )
        internal
        view
        returns (
            InvestorsStorage.Investor memory
        )
    {
        (
            uint investment,
            uint paymentTime,
            uint dividends,
            uint dividendsLimit,
            uint dividendsDeferred
        ) = m_investors.investorInfo(investorAddr);

        return InvestorsStorage.Investor(
            investment,
            paymentTime,
            InvestorsStorage.Dividends(
                dividends,
                dividendsLimit,
                dividendsDeferred)
        );
    }

    function calcDividends(address investorAddr) internal view returns(uint dividends) {
        InvestorsStorage.Investor memory investor = getMemInvestor(investorAddr);
        uint interval = 1 days;
        uint pastTime = now.sub(investor.paymentTime);

        // safe gas if dividends will be 0
        if (investor.investment.isZero() || pastTime < interval) {
            return 0;
        }

        // paid dividends cannot be greater then 150% from investor investment
        if (investor.dividends.value >= investor.dividends.limit) {
            return 0;
        }

        Percent.percent memory p = getDailyPercent(investor.investment);
        Percent.percent memory c = Percent.percent(p.num + p.den, p.den);

        uint intervals = pastTime.div(interval);
        uint totalDividends = investor.dividends.limit.add(investor.investment).sub(investor.dividends.value).sub(investor.dividends.deferred);

        dividends = investor.investment;
        for (uint i = 0; i < intervals; i++) {
            dividends = c.mmul(dividends);
            if (dividends > totalDividends) {
                dividends = totalDividends.add(investor.dividends.deferred);
                break;
            }
        }

        dividends = dividends.sub(investor.investment);

        //uint totalDividends = dividends + investor.dividends;
        //if (totalDividends >= investor.dividendsLimit) {
        //    dividends = investor.dividendsLimit - investor.dividends;
        //}
    }

    function getMaxDepositPercent() internal view returns(Percent.percent memory p) {
        p = m_maxDepositPercent.toMemory();
    }

    function getDailyPercent(uint value) internal view returns(Percent.percent memory p) {
        // (1) 1% if 0.01 ETH <= value < 0.1 ETH
        // (2) 1.5% if 0.1 ETH <= value < 1 ETH
        // (3) 2% if 1 ETH <= value < 5 ETH
        // (4) 2.5% if 5 ETH <= value < 10 ETH
        // (5) 3% if 10 ETH <= value < 20 ETH
        // (6) 3.5% if 20 ETH <= value < 30 ETH
        // (7) 4% if 30 ETH <= value <= 50 ETH

        if (MIN_INVESTMENT <= value && value < 100 finney) {
            p = m_1_percent.toMemory();                     // (1)
        } else if (100 finney <= value && value < 1 ether) {
            p = m_1_5_percent.toMemory();                   // (2)
        } else if (1 ether <= value && value < 5 ether) {
            p = m_2_percent.toMemory();                     // (3)
        } else if (5 ether <= value && value < 10 ether) {
            p = m_2_5_percent.toMemory();                   // (4)
        } else if (10 ether <= value && value < 20 ether) {
            p = m_3_percent.toMemory();                     // (5)
        } else if (20 ether <= value && value < 30 ether) {
            p = m_3_5_percent.toMemory();                   // (6)
        } else if (30 ether <= value && value <= MAX_INVESTMENT) {
            p = m_4_percent.toMemory();                     // (7)
        }
    }

    function getRefBonusPercent() internal view returns(Percent.percent memory p) {
        p = m_refPercent.toMemory();
    }

    function getReinvestBonusPercent() internal view returns(Percent.percent memory p) {
        p = m_reinvestPercent.toMemory();
    }
}
