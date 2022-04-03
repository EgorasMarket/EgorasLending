// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
struct AppStorage {
 address egorasEUSD;
  address  egorasEGC;
  address  eNFTAddress;
  address  egorasEGR;
  uint  votingThreshold;
  uint  systemFeeBalance;
  uint  requestCreationPower;
  uint  backers;
  uint  company;
  uint  branch;
  uint  dailyIncentive;
  uint currentPeriod;
  uint  nextRewardDate;
}