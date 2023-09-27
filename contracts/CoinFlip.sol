pragma solidity ^0.8.19;

import "D:\CoinFlip w VRF v2\node_modules\@chainlink\contracts\src\v0.8\vrf\VRFV2WrapperConsumerBase.sol"

contract CoinFlip is VRFV2 {

    enum CoinSide{
        Heads,
        Tails
    }

    //money to get entry
    uint constant entryfees = 0.001 ether;

    //upto how bmuch gas chainlink is willing to pay for my contract when they send back the result
    // bcz they will need to call a function in my contract and for that they need to pay a fee in ethereum network
    // so we will need to provide a maximum limit
    uint constant callbackgaslimit = 1_000_000;

    //how many random no we want
    uint constant numWords = 1;
    //how many confirmations do we need chainlink to wait for before generating a random no
    //the more blocks we wait the more higher gurrantee is for the transaction to work
    uint constant requestConfirmations= 3;

    struct Status {
        uint fees;
        uint randomword;
        address player;
        bool win;
        bool fulfilled;
        CoinSide choice;
    }
// to check the status of a particular user
    mapping (uint => Status) public statuses;

    address constant linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant VRFWrapperAddress = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625; //** */

    event Flip(uint requestid);
    event Result(uint requestid, bool win);

    constructor() VRFWrapperAddress(linkAddress,VRFWrapperAddress) payable {}


    function flip(CoinSide _choice) external payable returns(uint) {
        require(msg.value == entryfees,"not addequate amount of entry fees");

        uint requestid = requestRandomness(callbackgaslimit,requestConfirmations,numWords);

        statuses[requestid]= Status({
            fees: VRF_V2_WRAPPER.calculateRequestPrice(callbackgaslimit),
            randomword:0,
            player:msg.sender,
            win:false,
            fulfilled: false,
            choice:_choice;
        })

        emit Flip(requestid);
    }

    function fulfillRandomWords(uint _reqid, uint[] memory _randomword) internal override {
        require(statuses[_reqid].fees>0,"Request no found");
        statuses[_reqid].fulfilled = true;
        statuses[_reqid].randomword = _randomword[0];

        
        if(_randomword[0] %2 ==0) {
            result CoinSide.Tails;
        }else{
            result = CoinSide.Heads;
        }

        if(statuses[_reqid].choice==result){
            statuses[_reqid].win= true;
            payable(statuses[_reqid].player).transfer(entryfees*2);
        }

        emit Result(_reqid, statuses[_reqid].win);

    }

    function getStatus(uint _reqid) public view returns(Status memory){
        return statuses[_reqid];
    }
}
