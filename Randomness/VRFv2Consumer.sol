// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Interfaces/IRandomnessConsumer.sol";

contract VRFv2Consumer is VRFConsumerBaseV2, Ownable,IRandomnessConsumer {
    
    using SafeMath for uint256;

    event OnRandomnessRequested(uint256 requestId, uint32 numWords);
    event OnRandomnessFullfilled(uint256 requestId);
    event OnRandomed(address indexed _addr,uint256 value,bool is_pseudo_random);

    mapping(uint256 => uint256[]) private words; 
    
    mapping(uint256 => bool) private requested; 
    
    mapping(uint256 => bool) private fullfiled; 
    
    mapping(uint256 => uint256) private nounces; 

    VRFCoordinatorV2Interface private COORDINATOR;

    uint64 private subscription_id = 0;
    uint256 private last_requested_id = 0;
    uint256 private last_fullfilled_id = 0;
    bytes32 private gas_lane_hash = 0;
    uint32 private num_words = 100;

    //Must be alway greater or equals num_words.
    uint32 private max_nouce_for_refresh = 100;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    uint32 private callback_gaslimit = 2500000;

    // The default is 3, but you can set this higher.
    uint16 private request_confirmations = 3;

    constructor(uint64 subscription_id_,address vrf_coordinator_,bytes32 gas_lane_hash_,uint16 confirmation_)
        VRFConsumerBaseV2(vrf_coordinator_){
        COORDINATOR = VRFCoordinatorV2Interface(vrf_coordinator_);
        gas_lane_hash = gas_lane_hash_;
        subscription_id = subscription_id_;
        request_confirmations = (confirmation_ >= 3) ? confirmation_ : 3;
    }  
    function RefreshRandomness() external onlyOwner{
        refresh_randomness_internal();
    }
    function refresh_randomness_internal() internal returns (uint256){
        require(num_words > 0,"ZERO_WORDS");
        uint256 requestId = COORDINATOR.requestRandomWords(gas_lane_hash,subscription_id,request_confirmations,callback_gaslimit,num_words);
        requested[requestId] = true;
        last_requested_id = requestId;
        emit OnRandomnessRequested(requestId, num_words);
        return requestId;
    }
    function fulfillRandomWords(uint256 _request_id,uint256[] memory _words) internal override {
        require(requested[_request_id], "NOT_REQUEST");
        fullfiled[_request_id] = true;
        nounces[_request_id] = 0;
        words[_request_id] = _words;
        last_fullfilled_id = _request_id;
        emit OnRandomnessFullfilled(_request_id);
    } 
    function random(uint32 range) external returns (uint256){
        require(fullfiled[last_fullfilled_id],'NO_RANDOMNESS');
        
        bool shouldRefreshRandomness = nounces[last_fullfilled_id] >= max_nouce_for_refresh;
        bool shouldPseudoRandom = (nounces[last_fullfilled_id] >= words[last_fullfilled_id].length);
        uint256 index = nounces[last_fullfilled_id] % words[last_fullfilled_id].length;
        uint256 _rand_value = shouldPseudoRandom ? pseudo_random(range,nounces[last_fullfilled_id],words[last_fullfilled_id][index]) : (words[last_fullfilled_id][index] % range);
        nounces[last_fullfilled_id] = nounces[last_fullfilled_id].add(1);
        if(shouldRefreshRandomness && !is_on_refreshing())
            refresh_randomness_internal();
        emit OnRandomed(msg.sender,_rand_value,shouldPseudoRandom);
        return _rand_value;
    }
    
    function get_last_fullfill() public view returns (uint256) {return last_fullfilled_id;}
    
    function get_last_requested() public view returns (uint256) {return last_requested_id;}
    function get_num_words() public view returns (uint32) {return num_words;}
    function get_randomness(uint256 _request_id) public view returns (bool fulfilled,uint256, uint256[] memory randomWords) {
        return (fullfiled[_request_id],nounces[_request_id], words[_request_id]);
    }
    function get_max_nonce_for_refresh() public view returns(uint32)  {return max_nouce_for_refresh;}
    function is_on_refreshing() public view returns (bool) {
        return last_fullfilled_id != last_requested_id;
    }
    function set_num_words(uint32 num_words_) external onlyOwner {
        num_words = num_words_;
        if(num_words > max_nouce_for_refresh)
            max_nouce_for_refresh = num_words;
    }
    function set_max_nonce_for_refresh(uint32 max_nounce_) external onlyOwner {
        max_nouce_for_refresh = max_nounce_;
        if(max_nouce_for_refresh < num_words)
            num_words = max_nouce_for_refresh;
    }
    function set_gas_lane_hash(bytes32 keyhash) external onlyOwner {gas_lane_hash = keyhash;}
    function set_callback_gas_limit(uint32 gas_limit) external onlyOwner {callback_gaslimit = gas_limit;}
    function set_request_confirmation(uint16 confirmation) external onlyOwner {
        request_confirmations = (confirmation >= 3) ? confirmation : 3;
    }
    function change_coordinator(address coordinator) external onlyOwner {
        require(coordinator != address(0),"NULL_ADDRESS");
        COORDINATOR = VRFCoordinatorV2Interface(coordinator);
    }

    function pseudo_random(uint32 _range, uint256 _nonce, uint256 _seed) internal pure returns (uint256){
        uint8 _flagBits = uint8(255 - _msbDeBruijn32(_range));
        uint256 _number = uint256(keccak256(abi.encode(_seed, _nonce))) & uint256(2 ** _flagBits - 1);
        return ((_number * _range) >> _flagBits);
    }
    function _msbDeBruijn32(uint32 _v) internal pure returns (uint8){
        uint8[32] memory _bitPosition = [
                0, 9, 1, 10, 13, 21, 2, 29,
                11, 14, 16, 18, 22, 25, 3, 30,
                8, 12, 20, 28, 15, 17, 24, 7,
                19, 27, 23, 6, 26, 5, 4, 31
            ];
        _v |= _v >> 1;
        _v |= _v >> 2;
        _v |= _v >> 4;
        _v |= _v >> 8;
        _v |= _v >> 16;
        return _bitPosition[
            uint32(_v * uint256(0x07c4acdd)) >> 27
        ];
    }

    function get_gas_lane() public view returns (bytes32) {return gas_lane_hash;}
    function get_callback_gas_limit() public view returns (uint32) {return callback_gaslimit;}
    function get_request_confirmation() public view returns (uint16) {return request_confirmations;}
    function should_refresh_randomness() external view override returns (bool) {return nounces[last_fullfilled_id] >= max_nouce_for_refresh;}
    function get_random_nounce() external view override returns (uint256){return nounces[last_fullfilled_id];}
}
