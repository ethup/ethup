pragma solidity 0.4.25;

//solium-disable security/no-block-members


contract Accessibility {

    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "access denied");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function disown() internal {
        delete owner;
    }
}
