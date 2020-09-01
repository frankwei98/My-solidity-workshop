// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

interface IyDeposit {
  function add_liquidity ( uint256[4] calldata uamounts, uint256 min_mint_amount ) external;
  // Not using functions below, just uncomment what you wants to use
//   function remove_liquidity ( uint256 _amount, uint256[4] calldata min_uamounts ) external;
//   function remove_liquidity_imbalance ( uint256[4] calldata uamounts, uint256 max_burn_amount ) external;
//   function calc_withdraw_one_coin ( uint256 _token_amount, int128 i ) external returns ( uint256 );
//   function remove_liquidity_one_coin ( uint256 _token_amount, int128 i, uint256 min_uamount ) external;
//   function remove_liquidity_one_coin ( uint256 _token_amount, int128 i, uint256 min_uamount, bool donate_dust ) external;
//   function withdraw_donated_dust (  ) external;
//   function coins ( int128 arg0 ) external returns ( address );
//   function underlying_coins ( int128 arg0 ) external returns ( address );
//   function curve() external returns ( address );
//   function token() external returns ( address );
}
