pragma solidity 0.4.25;

import "./SafeMath.sol";


library Percent {
    using SafeMath for uint;

    // Solidity automatically throws when dividing by 0
    struct percent {
        uint num;
        uint den;
    }

    function mul(percent storage p, uint a) internal view returns (uint) {
        if (a == 0) {
            return 0;
        }
        return a.mul(p.num).div(p.den);
    }

    function div(percent storage p, uint a) internal view returns (uint) {
        return a.div(p.num).mul(p.den);
    }

    function sub(percent storage p, uint a) internal view returns (uint) {
        uint b = mul(p, a);
        if (b >= a) {
            return 0; // solium-disable-line lbrace
        }
        return a.sub(b);
    }

    function add(percent storage p, uint a) internal view returns (uint) {
        return a.add(mul(p, a));
    }

    function toMemory(percent storage p) internal view returns (Percent.percent memory) {
        return Percent.percent(p.num, p.den);
    }

    // memory
    function mmul(percent memory p, uint a) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        return a.mul(p.num).div(p.den);
    }

    function mdiv(percent memory p, uint a) internal pure returns (uint) {
        return a.div(p.num).mul(p.den);
    }

    function msub(percent memory p, uint a) internal pure returns (uint) {
        uint b = mmul(p, a);
        if (b >= a) {
            return 0;
        }
        return a.sub(b);
    }

    function madd(percent memory p, uint a) internal pure returns (uint) {
        return a.add(mmul(p, a));
    }
}
