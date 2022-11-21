import {expect} from "chai";
import {ethers} from "hardhat";
import { ERC20 } from "../typechain-types";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";

describe("MyERC20Contract",function(){

    let myERC20Contract:ERC20;
    let someAddress:SignerWithAddress;
    let someOtherAddress:SignerWithAddress;
    //deploying the contract 
    beforeEach(async function(){
        const ERC20ContractFactory=await ethers.getContractFactory("ERC20") //pass in name of contract we want. first we create a factory using function from Ethers. Previously we compiled the contract so its erc20 type
        myERC20Contract=await ERC20ContractFactory.deploy("Hello","SYM"); //deploy. the parameters - name and symbol
        await myERC20Contract.deployed(); //waiting for the contract to be fully deployed to blockchain

        //ethers.getSigners() get you all avaialble signers in local blockchain, the [0] one is used to deploy contract
        someAddress=(await ethers.getSigners())[1];
        someOtherAddress=(await ethers.getSigners())[2];
    });

    describe("When I have 10 tokens", function(){
        beforeEach(async function(){
           await myERC20Contract.transfer(someAddress.address,10);

        });

        describe("when i transfer 10 tokens",function(){
            it("should transfer tokens correctly",async function (){
                
                await myERC20Contract.connect(someAddress).transfer(someOtherAddress.address,10);
                expect(await myERC20Contract.balanceOf(someOtherAddress.address)).to.equal(10);

            })
        });

        describe("when i transfer 15 tokens",function(){
            it("should revert transaction",async function (){
                await expect(myERC20Contract.connect(someAddress).transfer(someOtherAddress.address,15)).to.be.revertedWith("ERC20: Transfer amt exceeds balance");
               

            })
        });
    });




})