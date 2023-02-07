// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "witnet-solidity-bridge/contracts/interfaces/IWitnetRandomness.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/IRandomnessConsumer.sol";

contract WitnetVRFConsumer is Ownable,IRandomnessConsumer {

    using SafeMath for uint256;

    uint256 private last_requested_blockno = 0;
    uint256 private max_nounce_to_refresh = 1000;

    IWitnetRandomness private witnet;
    
    event OnRandomnessRequested(uint256 block_no);
    event OnRandomed(address indexed _addr,uint256 value);

    constructor (address _witnet_randomness_addr) {
        assert(_witnet_randomness_addr != address(0));
        witnet = IWitnetRandomness(_witnet_randomness_addr);
        last_requested_blockno = witnet.latestRandomizeBlock();
    }

    mapping(uint256 => uint256) private nounces;

    receive () external payable {}
    
    function RefreshRandomness() external payable onlyOwner{
        require(address(witnet) != address(0),"NO_WITNET");
        uint256 usedFee = witnet.randomize{value: msg.value }();
        if (usedFee < msg.value)
            payable(msg.sender).transfer(msg.value - usedFee);
        last_requested_blockno = block.number;
        emit OnRandomnessRequested(last_requested_blockno);
    }
    function set_max_nounce_to_refresh(uint256 max_nounce_) external onlyOwner {
        require(max_nounce_ > 0,"ZERO_MAX_NOUNCE");
        max_nounce_to_refresh = max_nounce_;
    }
    function set_witnet(address witnet_) external onlyOwner {
        require(witnet_ != address(0),"ZERO_ADDRESS");
        witnet = IWitnetRandomness(witnet_);
    }

    function random(uint32 range) external returns (uint256) {
        require(address(witnet) != address(0),"NO_WITNET");
        uint256 fullfilled_block = witnet.latestRandomizeBlock();
        require(fullfilled_block > 0,"NO_RANDOM_BLOCK");
        require(witnet.isRandomized(fullfilled_block),"UNRANDOMABLE_BLOCK");
        uint256 _randed_value = witnet.random(range, nounces[fullfilled_block], fullfilled_block);
        nounces[fullfilled_block] = nounces[fullfilled_block].add(1);
        emit OnRandomed(msg.sender,_randed_value);
        return _randed_value;
    }
    function is_on_refreshing() public view returns (bool) {
        return (witnet.latestRandomizeBlock() != last_requested_blockno) && (last_requested_blockno > 0);
    }
    function get_last_requested_block() public view returns(uint256){return last_requested_blockno;}
    function get_last_fullfilled_block() public view returns(uint256){return witnet.latestRandomizeBlock();}
    function get_max_nounce_to_refresh() public view returns(uint256){return max_nounce_to_refresh;}
    
    function get_witnet() public view returns (address){return address(witnet);}
    function get_random_nounce() external view override returns(uint256){return address(witnet) != address(0) ? nounces[witnet.latestRandomizeBlock()] : 0;}
    function should_refresh_randomness() external view override returns (bool) {
        if(address(witnet) == address(0))
            return false;
        uint256 fullfilled_block = witnet.latestRandomizeBlock();
        return (nounces[fullfilled_block] > max_nounce_to_refresh);
    }
}