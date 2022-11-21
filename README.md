# Hardhat Project

# Solidity Exercise - making my own stablecoin
# Components of this erc20 stablecoin - FUN coin
Users have to deposit collateral (ethers).
Two roles in this smart contract - (role 1) deposit ETH to get stablecoins (role 2) Deposit eth only and get membership-coins for stake in smart contract's ether pool (leveraged ethers) 
Since price of ether may not always be increasing, and there may not be enough people who want leveraged ethers, this smart contract charges fee for getitng/redeeming stablecoins.
If ether price drops that ether pool is worth less than stablecoins value - disable redemption, destroy all membership-coins.
New users would be incenticized to deposit ether to pool so as to have greater stake in pool 


