#!/bin/bash
set -e

# clone this branch next to governance-ui: https://github.com/blockworks-foundation/solana/tree/max/dump-poa
# build with `rustup override set 1.65.0-aarch64-apple-darwin; cargo build`
# use locally compiled solana-cli binaries to access new dump features
# in Code/governance-ui run ./scripts/bootstrap-localnet.sh
# so it finds Code/solana/target/debug/solana
export PATH="../solana/target/debug:$PATH"

output_path="dump"

# clean up data from previous runs
rm -rf $output_path

# download solana-lab's versions of spl-governance as well as mango's versions of spl-governance & VSR
for program_id in GovER5Lthms3bLBqWub97yVrMmEogzX7xNjdXpPPCVZw GqTPL6qRf5aUuqscLh8Rg2HTxPUXfhhAXDptTLhp1t2J 4Q6WW2ouZ6V3iaNm56MTd5n2tnTm4C5fiH8miFHnAFHo
do
 echo "downloading program binary and accounts to $output_path/$program_id"
 mkdir -p $output_path/$program_id/accounts
 solana program dump-executable $program_id $output_path/$program_id/program.so
 solana program dump-owned-accounts $program_id $output_path/$program_id/accounts
 # manually fetch accounts so programs are upgradeable
 solana account -o $output_path/$program_id/accounts/$program_id.json --output json $program_id
 buffer_id=$(solana program show $program_id --output json | jq -r '.programdataAddress')
 solana account -o $output_path/$program_id/accounts/$buffer_id.json --output json $buffer_id
done

# save wallet used for simulation of VSR accounts
solana account -o $output_path/GovER5Lthms3bLBqWub97yVrMmEogzX7xNjdXpPPCVZw/accounts/ENmcpFCpxN1CqyUjuog9yyUVfdXBKF3LVCwLr7grJZpk.json --output json ENmcpFCpxN1CqyUjuog9yyUVfdXBKF3LVCwLr7grJZpk
solana account -o $output_path/GovER5Lthms3bLBqWub97yVrMmEogzX7xNjdXpPPCVZw/accounts/8pueehTroUBwL1EQAkjr2DNa2HEoRwQpiUF1s8F7duzd.json --output json 8pueehTroUBwL1EQAkjr2DNa2HEoRwQpiUF1s8F7duzd


# find token accounts & mints to download through parsing all governances of the realm

# multi-sig on solana-labs' realms instance
export OUT=$output_path
export GOV_PROGRAM_ID=GovER5Lthms3bLBqWub97yVrMmEogzX7xNjdXpPPCVZw
export REALM_ID=Eb69t8zTkNbBViLRykbgBofr8PbwvZoAX4KicVcNNwkj
yarn ts-node scripts/governance-dump.ts || exit

# mango dao on it's own realms instance
export GOV_PROGRAM_ID=GqTPL6qRf5aUuqscLh8Rg2HTxPUXfhhAXDptTLhp1t2J
export VSR_PROGRAM_ID=4Q6WW2ouZ6V3iaNm56MTd5n2tnTm4C5fiH8miFHnAFHo
export REALM_ID=DPiH3H3c7t47BMxqTxLsuPQpEC6Kne8GA9VXbxpnZxFE
yarn ts-node scripts/governance-dump.ts || exit


# launch a local validator
solana-test-validator --reset \
  --account-dir $output_path/GovER5Lthms3bLBqWub97yVrMmEogzX7xNjdXpPPCVZw/accounts \
  --account-dir $output_path/GqTPL6qRf5aUuqscLh8Rg2HTxPUXfhhAXDptTLhp1t2J/accounts \
  --account-dir $output_path/4Q6WW2ouZ6V3iaNm56MTd5n2tnTm4C5fiH8miFHnAFHo/accounts

