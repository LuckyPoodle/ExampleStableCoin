// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {ERC20} from "./ERC20.sol";

contract MembershipCoin is ERC20{

    address public owner;
    constructor() ERC20("MembershipCoin","MEM"){
        owner=msg.sender; //shall be the smart contract when it deploys this membershipcoin
    }
    
    function mint(address to,uint256 amount) external{
        require(msg.sender==owner,"MEM: only owner can mint");
        _mint(to,amount);
    }
    

    function burn(address from,uint256 amount) external{
        require(msg.sender==owner,"MEM: only owner can burn");
        _burn(from,amount);
    }
    










}

