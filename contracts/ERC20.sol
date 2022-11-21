//SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

contract ERC20{
    uint256 public totalSupply;
    string public name;
    string public symbol;
    event Transfer(address indexed from,address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender,uint256 value);
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;

    constructor (string memory _name, string memory _symbol){
        name=_name;
        symbol=_symbol;
       // _mint(msg.sender,500e18); // tokens minted to the deployer

    }
    //cheaper gas to declare like this, hardcoded decimal
    function decimals() external pure returns (uint8){
        return 18;
    }
    //transfer token to the new address, anyone who owns the token can transfer
    function transfer(address recipient,uint256 amount) external returns (bool){
      return _transfer(msg.sender,recipient,amount);
    }

    function deposit(address sender) public payable  {
        _mint(msg.sender,msg.value);
    }
    function redeem(uint256 numToRedeem,address recipient) public payable{
        _burn(msg.sender,numToRedeem);
        (bool success,)=payable(msg.sender).call{value:numToRedeem}("");
        require(success,"redeem function failed");
    }
    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "ERC20: burn from the zero address");
        totalSupply -= amount;
        balanceOf[from] -= amount;
        emit Transfer(from, address(0), amount);

    }
    function transferFrom(address sender,address recipient, uint256 amount) external returns (bool){
        uint256 currentAllowance=allowance[sender][msg.sender];
        require(currentAllowance>=amount,"ERC20: transfer amount exceeds allowance");
        allowance[sender][msg.sender]=currentAllowance-amount;
        emit Approval (sender,msg.sender,allowance[sender][msg.sender]); //new allowance
        return _transfer(sender,recipient,amount);
    }

    function _transfer(address sender,address recipient,uint256 amount) private returns (bool){
        require(recipient!=address(0),"ERC20: Transfer to zero address");
        uint256 senderBalance=balanceOf[msg.sender];
        require(senderBalance>=amount,"ERC20: Transfer amt exceeds balance");
        balanceOf[msg.sender]=senderBalance-amount;
        balanceOf[recipient]+=amount;
        emit Transfer(sender,recipient,amount);
        return true;
    }
    function _mint(address to, uint256 amount) internal{ //we mint some tokens to the person who is deploying the contract
        require(to!=address(0),"ERC20: mint to zero");
        totalSupply+=amount;
        balanceOf[to]+=amount;
        emit Transfer(address(0),to,amount); 
    }
    function approve(address spender,uint256 amount)external returns (bool){
        require(spender!=address(0),"ERC20: Approve to zero");
        //prevent front-running attack
        require(amount==0 || allowance[msg.sender][spender]==0);

        allowance[msg.sender][spender]=amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }


}
