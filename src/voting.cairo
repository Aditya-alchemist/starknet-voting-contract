#[starknet::interface]
trait IContract<C> {
    fn addvoter(ref self: C, address: starknet::ContractAddress);
    fn checkvotercanvote(self: @C, address: starknet::ContractAddress) -> bool;
    fn vote(ref self: C, vote: starknet::ContractAddress);
    fn returnvotes(self: @C, candidate: starknet::ContractAddress) -> u32;
}

#[starknet::contract]
mod votingupdated {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess,Map,StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        voter: Map<ContractAddress, bool>,
        candidate: Map<ContractAddress, u32>,
        candidateA: ContractAddress,
        candidateB: ContractAddress,
        candidateC: ContractAddress,
        owner: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        candidate_a: ContractAddress,
        candidate_b: ContractAddress,
        candidate_c: ContractAddress,
        owner: ContractAddress
    ) {
        self.candidateA.write(candidate_a);
        self.candidateB.write(candidate_b);
        self.candidateC.write(candidate_c);
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl Contract of super::IContract<ContractState> {
        fn addvoter(ref self: ContractState, address: ContractAddress) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'Only owner can call');
            self.voter.write(address, true);
        }

        fn checkvotercanvote(self: @ContractState, address: ContractAddress) -> bool {
            self.voter.read(address)
        }

        fn vote(ref self: ContractState, vote: ContractAddress) {
            let caller = get_caller_address();
            let is_voter = self.checkvotercanvote(caller);
            if !is_voter {
                panic_with_felt252('Not eligible to vote');
            }

            let current_votes = self.candidate.read(vote);
            self.candidate.write(vote, current_votes + 1);
            self.voter.write(caller, false); // mark as voted
        }

        fn returnvotes(self: @ContractState, candidate: ContractAddress) -> u32 {
            self.candidate.read(candidate)
        }
    }
}
