// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {ERC20} from "./ERC20.sol";
import {MembershipCoin} from "./MembershipCoin.sol";
import {Oracle} from "./Oracle.sol";
import {WadLib} from "./WadLib.sol";

contract FunStableCoin is ERC20 {
    using WadLib for uint256;

    error InitialCollateralRatioError(
        string message,
        uint256 minimumDepositAmount
    );

    MembershipCoin public membershipCoin;
    Oracle public oracle;
    uint256 public feeRatePercentage;
    uint256 public constant INITIAL_COLLATERAL_RATIO_PERCENTAGE = 10;

    constructor(uint256 _feeRatePercentage, Oracle _oracle)
        ERC20("FunStableCoin", "FUN")
    {
        feeRatePercentage = _feeRatePercentage;
        oracle = _oracle;
    }

    function mint() external payable {
        uint256 fee = _getFee(msg.value);
        uint256 remainingEth = msg.value - fee;

        uint256 mintStableCoinAmount = remainingEth * oracle.getPrice();
        _mint(msg.sender, mintStableCoinAmount);
    }

    function burn(uint256 burnStableCoinAmount) external {
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();
        require(
            deficitOrSurplusInUsd >= 0,
            "FUN: Cannot burn while in deficit"
        );

        _burn(msg.sender, burnStableCoinAmount);

        uint256 refundingEth = burnStableCoinAmount / oracle.getPrice();
        uint256 fee = _getFee(refundingEth);
        uint256 remainingRefundingEth = refundingEth - fee;

        (bool success, ) = msg.sender.call{value: remainingRefundingEth}("");
        require(success, "FUN: Burn refund transaction failed");
    }

    function _getFee(uint256 ethAmount) private view returns (uint256) {
        bool hasDepositors = address(membershipCoin) != address(0) &&
            membershipCoin.totalSupply() > 0;
        if (!hasDepositors) {
            return 0;
        }

        return (feeRatePercentage * ethAmount) / 100;
    }

    function depositCollateralBuffer() external payable {
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();

        if (deficitOrSurplusInUsd <= 0) {
            uint256 deficitInUsd = uint256(deficitOrSurplusInUsd * -1);
            uint256 usdInEthPrice = oracle.getPrice();
            uint256 deficitInEth = deficitInUsd / usdInEthPrice;

            uint256 requiredInitialSurplusInUsd = (INITIAL_COLLATERAL_RATIO_PERCENTAGE *
                    totalSupply) / 100;
            uint256 requiredInitialSurplusInEth = requiredInitialSurplusInUsd /
                usdInEthPrice;

            if (msg.value < deficitInEth + requiredInitialSurplusInEth) {
                uint256 minimumDepositAmount = deficitInEth +
                    requiredInitialSurplusInEth;
                revert InitialCollateralRatioError("FUN: Initial collateral ratio not met, mimimum is ",
                    minimumDepositAmount
                );
            }

            uint256 newInitialSurplusInEth = msg.value - deficitInEth;
            uint256 newInitialSurplusInUsd = newInitialSurplusInEth *
                usdInEthPrice;

            membershipCoin = new MembershipCoin();
            uint256 mintDepostorCoinAmount = newInitialSurplusInUsd;
            membershipCoin.mint(msg.sender, mintDepostorCoinAmount);

            return;
        }

        uint256 surplusInUsd = uint256(deficitOrSurplusInUsd);
        WadLib.Wad MEMInUsdPrice = _getMEMinUsdPrice(surplusInUsd);
        uint256 mintMembershipCoinAmount = ((msg.value.mulWad(MEMInUsdPrice)) /
            oracle.getPrice());

        membershipCoin.mint(msg.sender, mintMembershipCoinAmount);
    }

    function withdrawCollateralBuffer(uint256 burnMembershipCoinAmount)
        external
    {
        require(
            membershipCoin.balanceOf(msg.sender) >= burnMembershipCoinAmount,
            "FUN: Sender has insuffient MEM funds"
        );

        membershipCoin.burn(msg.sender, burnMembershipCoinAmount);

        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();
        require(deficitOrSurplusInUsd > 0, "FUN: No funds to withdraw");

        uint256 surplusInUsd = uint256(deficitOrSurplusInUsd);
        WadLib.Wad MEMInUsdPrice = _getMEMinUsdPrice(surplusInUsd);
        uint256 refundingUsd = burnMembershipCoinAmount.mulWad(MEMInUsdPrice);
        uint256 refundingEth = refundingUsd / oracle.getPrice();

        (bool success, ) = msg.sender.call{value: refundingEth}("");
        require(success, "FUN: Withdraw refund transaction failed");
    }

    function _getDeficitOrSurplusInContractInUsd()
        private
        view
        returns (int256)
    {
        uint256 ethContractBalanceInUsd = (address(this).balance - msg.value) *
            oracle.getPrice();
        uint256 totalStableCoinBalanceInUsd = totalSupply;
        int256 deficitOrSurplus = int256(ethContractBalanceInUsd) -
            int256(totalStableCoinBalanceInUsd);

        return deficitOrSurplus;
    }

    function _getMEMinUsdPrice(uint256 surplusInUsd)
        private
        view
        returns (WadLib.Wad)
    {
        return WadLib.fromFraction(membershipCoin.totalSupply(), surplusInUsd);
    }
}