// use starknet::{ContractAddress, get_caller_address, get_contract_address,
// contract_address_const};
use afk::interfaces::voting::{ConfigParams, ConfigResponse};
use afk::social::profile::NostrProfile;
use afk::social::request::SocialRequest;
use afk::social::transfer::Transfer;
use starknet::account::Call;
use starknet::{ContractAddress};

#[starknet::interface]
pub trait IDaoAA<TContractState> {
    fn get_public_key(self: @TContractState) -> u256;
    fn get_token_contract_address(self: @TContractState) -> ContractAddress;
    fn update_config(ref self: TContractState, config_params: ConfigParams);
    fn get_config(self: @TContractState) -> ConfigResponse;
    fn set_public_key(ref self: TContractState, public_key: u256);
    // fn __execute__(self: @TContractState, calls: Array<Call>) -> Array<Span<felt252>>;
// fn __validate__(self: @TContractState, calls: Array<Call>) -> felt252;
// fn is_valid_signature(self: @TContractState, hash: felt252, signature: Array<felt252>) ->
// felt252;
}

#[starknet::interface]
pub trait ISRC6<TContractState> {
    fn __execute__(ref self: TContractState, calls: Array<Call>) -> Array<Span<felt252>>;
    fn __validate__(self: @TContractState, calls: Array<Call>) -> felt252;
    fn is_valid_signature(
        self: @TContractState, hash: felt252, signature: Array<felt252>
    ) -> felt252;
}


#[starknet::contract(account)]
pub mod DaoAA {
    use afk::bip340::{Signature, SchnorrSignature};
    use afk::bip340;
    use afk::interfaces::voting::{
        IVoteProposal, Proposal, ProposalParams, ProposalResult, ProposalType, UserVote, VoteState,
        ProposalCreated, SET_PROPOSAL_DURATION_IN_SECONDS, TOKEN_DECIMALS, ProposalVoted,
        ProposalResolved, ConfigParams, ConfigResponse, ProposalCanceled, Calldata,
    };
    use afk::social::request::{SocialRequest, SocialRequestImpl, SocialRequestTrait, Encode};
    use afk::social::transfer::Transfer;
    use afk::tokens::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use afk::utils::{
        MIN_TRANSACTION_VERSION, QUERY_OFFSET, execute_calls // is_valid_stark_signature
    };
    use core::ecdsa::check_ecdsa_signature;
    use core::hash::{HashStateExTrait, HashStateTrait};
    use core::num::traits::Zero;
    use core::poseidon::{PoseidonTrait, poseidon_hash_span};
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin::governance::timelock::TimelockControllerComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;
    use openzeppelin::utils::cryptography::snip12::StructHash;
    use starknet::account::Call;

    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
        StorageMapWriteAccess, Vec, MutableVecTrait,
    };
    use starknet::{
        get_caller_address, get_contract_address, get_tx_info, ContractAddress,
        contract_address_const,
    };
    use super::ISRC6;
    use super::{IDaoAADispatcher, IDaoAADispatcherTrait};

    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    // component!(path: TimelockControllerComponent, storage: timelock, event: TimelockEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    pub const ISRC6_ID: felt252 = 0x2ceccef7f994940b3962a6c67e0ba4fcd37df7d131417c604f91e03caecc1cd;

    // AccessControl
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    // // Timelock Mixin
    // #[abi(embed_v0)]
    // impl TimelockMixinImpl =
    //     TimelockControllerComponent::TimelockMixinImpl<ContractState>;
    // impl TimelockInternalImpl = TimelockControllerComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[key]
        public_key: u256,
        owner: ContractAddress,
        is_admin_bypass_available: bool,
        is_only_dao_execution: bool,
        // Voting storage
        token_contract_address: ContractAddress,
        minimal_balance_voting: u256,
        max_balance_per_vote: u256,
        minimal_balance_create_proposal: u256,
        is_multi_vote_available_per_token_balance: bool,
        minimum_threshold_percentage: u64,
        transfers: Map<u256, bool>,
        proposals: Map<u256, Option<Proposal>>, // Map ProposalID => Proposal
        proposals_calldata: Map<u256, Vec<Calldata>>, // Map ProposalID => calldata
        proposal_by_user: Map<ContractAddress, u256>,
        total_proposal: u256,
        executable_tx: Map<
            (felt252, u64), bool
        >, // Map (Hashed Call, executable_count) => executable, for extra security.
        proposal_tx: Map<
            u256, Vec<felt252>
        >, // Map Proposal ID => Hashed Call (for one call, multicall excluded)
        vote_state_by_proposal: Map<u256, VoteState>, // Map ProposalID => VoteState
        // vote_by_proposal: Map<u256, Proposal>,
        tx_data_per_proposal: Map<u256, Span<felt252>>, // 
        starknet_address: felt252,
        executables_count: u64,
        executed_count: u64, // for __execute__ security.
        max_executable_clone: Map<
            felt252, u64
        >, // variable for optimized iteration. stores the highest
        current_max_tx_count: u64, // optimized for get iteration
        // votes_by_proposal: Map<u256, u256>, // Maps proposal ID to vote count
        // here
        // user_votes: Map<
        //     (u256, ContractAddress), u64,
        // >, // Maps user address to proposal ID they voted for
        // has_voted: Map<(u256, ContractAddress), bool>,
        // user_vote_type: Map<(u256, ContractAddress), UserVote>,
        total_voters: u128,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        AccountCreated: AccountCreated,
        ProposalCreated: ProposalCreated,
        ProposalVoted: ProposalVoted,
        ProposalCanceled: ProposalCanceled,
        ProposalResolved: ProposalResolved,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct AccountCreated {
        #[key]
        public_key: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        token_contract_address: ContractAddress,
        public_key: u256,
        starknet_address: felt252
    ) {
        // self.public_key.write(public_key);
        self.owner.write(owner);
        self.token_contract_address.write(token_contract_address);
        self.total_proposal.write(0);
        self.is_only_dao_execution.write(true);
        self.minimum_threshold_percentage.write(60);
        // TODO: init self.starknet_address here
        self.starknet_address.write(starknet_address);
        self.src5.register_interface(ISRC6_ID);
        // self.accesscontrol.initializer();
        // self.accesscontrol._grant_role(ADMIN_ROLE, owner);
        // self.accesscontrol._grant_role(MINTER_ROLE, admin);
        self.emit(AccountCreated { public_key: public_key });
    }

    #[abi(embed_v0)]
    impl DaoAA of super::IDaoAA<ContractState> {
        fn get_public_key(self: @ContractState) -> u256 {
            self.public_key.read()
        }

        fn get_token_contract_address(self: @ContractState) -> ContractAddress {
            self.token_contract_address.read()
        }

        fn update_config(ref self: ContractState, config_params: ConfigParams) {
            self._update_config(config_params);
        }

        fn get_config(self: @ContractState) -> ConfigResponse {
            self._get_config()
        }

        fn set_public_key(ref self: ContractState, public_key: u256) {
            assert(get_caller_address() == self.owner.read(), 'UNAUTHORIZED CALLER');
            self.public_key.write(public_key);
        }
    }

    #[abi(embed_v0)]
    impl DaoAAProposalImpl of IVoteProposal<ContractState> {
        // TODO
        // Check if ERC20 minimal balance to create a proposal is needed, if yes check the  balance
        // Add TX Calldata for this proposal
        fn create_proposal(
            ref self: ContractState, proposal_params: ProposalParams, calldata: Array<Call>,
        ) -> u256 {
            let owner = get_caller_address();
            let minimal_balance = self.minimal_balance_create_proposal.read();

            // for now, proposals cannot be created without a calldata
            assert(calldata.len() > 0, 'NO CALLDATA PRESENT');

            if minimal_balance > 0 {
                let vote_token_dispatcher = IERC20Dispatcher {
                    contract_address: self.token_contract_address.read(),
                };
                assert(
                    vote_token_dispatcher.balance_of(owner) > minimal_balance,
                    'INSUFFICIENT CREATION FUNDS',
                );
            }

            let id = self.total_proposal.read() + 1;
            let created_at = starknet::get_block_timestamp();
            let end_at = starknet::get_block_timestamp() + SET_PROPOSAL_DURATION_IN_SECONDS;

            let proposal = Proposal {
                id,
                created_at,
                end_at,
                is_whitelisted: false,
                proposal_params,
                proposal_status: Default::default(),
                proposal_result: Default::default(),
                proposal_result_at: 0,
                owner,
                proposal_result_by: contract_address_const::<0x0>(),
            };

            // check
            self.proposals.entry(id).write(Option::Some(proposal));

            self._resolve_proposal_calldata(id, calldata);
            self.total_proposal.write(id);
            self.emit(ProposalCreated { id, owner, created_at, end_at });

            id
        }

        fn cast_vote(ref self: ContractState, proposal_id: u256, opt_vote_type: Option<UserVote>) {
            // TODO
            // Check if ERC20 minimal balance is needed
            // Check if ERC20 max balance is needed
            // Check is_multi_vote_available_per_token_balance

            // Finish the voting part
            // done
            let voted_at = starknet::get_block_timestamp();
            let caller = get_caller_address();
            let proposal = self._get_proposal(proposal_id);
            assert(proposal.proposal_result == Default::default(), 'CANNOT VOTE ON PROPOSAL');
            assert(voted_at < proposal.end_at, 'PROPOSAL HAS ENDED');
            let mut vote_state = self.vote_state_by_proposal.entry(proposal_id);
            assert(
                !vote_state.user_has_voted.entry(caller).read()
                    && !self.is_multi_vote_available_per_token_balance.read(),
                'CALLER HAS VOTED',
            );

            // Use balance for vote power
            let vote_token_dispatcher = IERC20Dispatcher {
                contract_address: self.token_contract_address.read(),
            };
            let caller_balance = vote_token_dispatcher
                .balance_of(caller); // this is without its decimals
            // let number_of_votes: u64 = (caller_balance /
            // TOKEN_DECIMALS.into()).try_into().unwrap();

            let max_votes = self.max_balance_per_vote.read();
            assert(
                caller_balance > 0 && caller_balance >= self.minimal_balance_voting.read(),
                'INSUFFICIENT VOTING FUNDS',
            );

            let mut caller_votes = if caller_balance > max_votes && max_votes > 0 {
                max_votes
            } else {
                caller_balance
            };

            let previous_voter_count = vote_state.voter_count.read();
            vote_state.voter_count.write(previous_voter_count + 1);

            let vote_type: UserVote = match opt_vote_type {
                Option::Some(vote_type) => vote_type,
                _ => Default::default(),
            };

            vote_state.user_votes.entry(caller).write((vote_type, caller_votes));
            vote_state.user_has_voted.entry(caller).write(true);
            vote_state.voters_list.append().write(caller);
            self.total_voters.write(self.total_voters.read() + 1);

            // NOTE: Config for abstention currently does nothing in this function
            if vote_type == UserVote::Yes {
                let (mut yes_votes, mut vote_point) = vote_state.yes_votes.read();
                vote_state.yes_votes.write((yes_votes + 1, vote_point + caller_votes));
            } else if vote_type == UserVote::No {
                let (mut no_votes, mut vote_point) = vote_state.no_votes.read();
                vote_state.no_votes.write((no_votes + 1, vote_point + caller_votes));
            } else {
                caller_votes = 0;
            };

            let previous_vote_count = vote_state.no_of_votes.read();
            vote_state.no_of_votes.write(previous_vote_count + caller_votes);

            self
                .emit(
                    ProposalVoted {
                        id: proposal_id,
                        voter: caller,
                        vote: vote_type,
                        votes: caller_votes,
                        total_votes: previous_vote_count + caller_votes,
                        voted_at,
                    },
                );
        }

        // fn get_vote_state(ref self: ContractState, proposal_id: u256) -> VoteState {
        //     let caller = get_caller_address();
        //     self.vote_by_proposal.read(proposal_id)
        // }

        fn get_proposal(self: @ContractState, proposal_id: u256) -> Proposal {
            self._get_proposal(proposal_id)
        }

        fn get_user_vote(
            self: @ContractState, proposal_id: u256, user: ContractAddress,
        ) -> UserVote {
            let caller = get_caller_address();
            let _ = self._get_proposal(proposal_id); // assert
            let mut vote_state = self.vote_state_by_proposal.entry(proposal_id);
            assert(vote_state.user_has_voted.entry(caller).read(), 'CALLER HAS NO VOTES');

            let (user_vote, _) = vote_state.user_votes.entry(caller).read();
            user_vote
        }

        fn cancel_proposal(ref self: ContractState, proposal_id: u256) {
            let mut proposal = self._get_proposal(proposal_id);
            assert(get_caller_address() == proposal.owner, 'UNAUTHORIZED CALLER');
            assert(proposal.proposal_result == Default::default(), 'CANNOT CANCEL PROPOSAL');
            proposal.proposal_result = ProposalResult::Canceled;
            self.proposals.entry(proposal_id).write(Option::Some(proposal));

            self
                .emit(
                    ProposalCanceled {
                        id: proposal_id, owner: get_caller_address(), is_canceled: true,
                    },
                );
        }

        fn process_result(ref self: ContractState, proposal_id: u256) {
            let mut proposal = self._get_proposal(proposal_id);
            assert(
                proposal.proposal_result == Default::default()
                    && starknet::get_block_timestamp() > proposal.end_at,
                'CANNOT PROCESS PROPOSAL',
            );

            // Implement result logic
            // Implement logic, brings us back to the execute
            // TODO: Implement execute in the future if Proposal is validated
            // for now, we just process the yes and no votes, update proposal state and emit an
            // event.
            let mut vote_state = self.vote_state_by_proposal.entry(proposal_id);

            let (yes_votes, _) = vote_state.yes_votes.read();
            let (no_votes, _) = vote_state.no_votes.read();

            // NOTE: The abstention votes are not used in this calculation
            // do well to reconfirm. For now, we use total_votes as:
            let total_votes = yes_votes + no_votes;
            let valid_threshold_percentage = yes_votes * 100 / total_votes;

            if valid_threshold_percentage >= self.minimum_threshold_percentage.read() {
                let mut executables_count = self.executables_count.read() + 1;
                proposal.proposal_result = ProposalResult::Passed;

                let proposal_txs = self.proposal_tx.entry(proposal_id);

                // extract list of txs for the given proposal
                for i in 0
                    ..proposal_txs
                        .len() {
                            let proposal_tx = proposal_txs.at(i).read();
                            // further optimized.
                            // situation where different proposals have the same calldata to
                            // execute.
                            let mut tx_count = self.max_executable_clone.entry(proposal_tx).read()
                                + 1;

                            self.executable_tx.entry((proposal_tx, tx_count)).write(true);
                            let mut current_max_tx_count = self.current_max_tx_count.read();
                            // update the current max if the new tx_count is > current_max_tx_count
                            if tx_count > current_max_tx_count {
                                self.current_max_tx_count.write(tx_count);
                            }
                            self.max_executable_clone.entry(proposal_tx).write(tx_count);
                            executables_count += 1;
                        };

                // update the number of executables adequately
                self.executables_count.write(executables_count);
            } else {
                proposal.proposal_result = ProposalResult::Failed;
            }

            self
                .emit(
                    ProposalResolved {
                        id: proposal_id, owner: proposal.owner, result: proposal.proposal_result,
                    },
                );
            self.proposals.entry(proposal_id).write(Option::Some(proposal));
        }

        fn is_executable(ref self: ContractState, calldata: Call) -> bool {
            let mut is_executable = false;
            let calldata_hash = calldata.hash_struct();
            let max_executable_clone = self.max_executable_clone.entry(calldata_hash).read() + 1;
            for i in 0
                ..max_executable_clone {
                    if self.executable_tx.entry((calldata_hash, i)).read() {
                        is_executable = true;
                        break;
                    }
                };
            is_executable
        }
    }

    #[abi(embed_v0)]
    impl ISRC6Impl of ISRC6<ContractState> {
        //  TODO
        // Verify the TX is automated of the proposal is valid for this calldata
        // CENSORED the owner/signature for a real AA Autonomous for DAO and agents

        // TODO, security issue.
        fn __execute__(ref self: ContractState, calls: Array<Call>) -> Array<Span<felt252>> {
            assert!(get_caller_address().is_zero(), "invalid caller");

            let mut verified_calls: Array<(felt252, u64)> = array![];
            // Verify calls before executing
            for i in 0
                ..calls
                    .len() {
                        // iterate through the max_executable_clone for each tx.
                        let current_call = *calls.at(i);
                        let current_call_hash = current_call.hash_struct();
                        let max_tx_count = self
                            .max_executable_clone
                            .entry(current_call_hash)
                            .read();
                        let mut tx_count = 1;
                        let mut is_executable = false;
                        while tx_count <= max_tx_count {
                            is_executable = self
                                .executable_tx
                                .entry((current_call_hash, tx_count))
                                .read();
                            if is_executable {
                                // mark the call as executed (now as a non-executable)
                                // not yet, add to list of verified calls
                                // self
                                //     .executable_tx
                                //     .entry((current_call_hash, tx_count))
                                //     .write(false);
                                verified_calls.append((current_call_hash, tx_count));
                                break;
                            }
                            tx_count += 1;
                        };
                        assert(is_executable, 'CALL VALIDATION ERROR');
                        // TODO
                    // currently there's no way to set a Proposal as executed because this task
                    // will require the proposals id. In that case, it must be done manually.
                    };

            // // Check tx version
            // let tx_info = get_tx_info().unbox();
            // let tx_version: u256 = tx_info.version.into();
            // // Check if tx is a query
            // if (tx_version >= QUERY_OFFSET) {
            //     assert!(QUERY_OFFSET + MIN_TRANSACTION_VERSION <= tx_version, "invalid tx
            //     version");
            // } else {
            //     assert!(MIN_TRANSACTION_VERSION <= tx_version, "invalid tx version");
            // }

            let executed_calls = execute_calls(calls);

            // mark all as executed.
            for verified_call in verified_calls {
                self.executable_tx.entry(verified_call).write(false);
                self.executed_count.write(self.executed_count.read() + 1);
            };

            executed_calls
        }

        //  TODO
        // Verify the TX is automated of the proposal is valid for this calldata
        // CENSORED the owner/signature for a real AA Autonomous for DAO and agents
        fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
            let tx_info = get_tx_info().unbox();
            self._is_valid_signature(tx_info.transaction_hash, tx_info.signature)
        }

        fn is_valid_signature(
            self: @ContractState, hash: felt252, signature: Array<felt252>,
        ) -> felt252 {
            self._is_valid_signature(hash, signature.span())
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        //  TODO
        // Verify the TX is automated of the proposal is valid for this calldata
        // CENSORED the owner/signature for a real AA Autonomous for DAO and agents
        fn _is_valid_signature(
            self: @ContractState, hash: felt252, signature: Span<felt252>,
        ) -> felt252 {
            let is_valid_length = signature.len() == 2_u32;
            // assert(is_valid_length, 'Account: Incorrect tx signature');

            if !is_valid_length {
                return 'INVALID_LENGTH';
            }

            // is this variable from the storage?
            let account_address: felt252 = self.starknet_address.read().try_into().unwrap();
            let is_valid = check_ecdsa_signature(
                hash, account_address, *signature.at(0_u32), *signature.at(1_u32),
            );
            if is_valid {
                return starknet::VALIDATED;
            }
            // assert(is_valid, 'INVALIDATED');
            0
            // let public_key = self.public_key.read();

            // let mut signature = signature;
        // let r: u256 = Serde::deserialize(ref signature).expect('invalid signature format');
        // let s: u256 = Serde::deserialize(ref signature).expect('invalid signature format');

            // let hash: u256 = hash.into();
        // let mut hash_as_ba = Default::default();
        // hash_as_ba.append_word(hash.high.into(), 16);
        // hash_as_ba.append_word(hash.low.into(), 16);

            // if bip340::verify(public_key, r, s, hash_as_ba) {
        //     starknet::VALIDATED
        // } else {
        //     0
        // }
        }

        fn _get_proposal(self: @ContractState, proposal_id: u256) -> Proposal {
            let opt_proposal = self.proposals.entry(proposal_id).read();
            assert(opt_proposal.is_some(), 'INVALID PROPOSAL ID');

            opt_proposal.unwrap()
        }

        fn _update_config(ref self: ContractState, config_params: ConfigParams) {
            // Updates all possible proposal configuration for
            assert(get_caller_address() == self.owner.read(), 'UNAUTHORIZED CALLER');
            if let Option::Some(var) = config_params.is_admin_bypass_available {
                self.is_admin_bypass_available.write(var);
            }
            if let Option::Some(var) = config_params.is_only_dao_execution {
                self.is_only_dao_execution.write(var);
            }
            if let Option::Some(var) = config_params.token_contract_address {
                self.token_contract_address.write(var);
            }
            if let Option::Some(var) = config_params.minimal_balance_voting {
                self.minimal_balance_voting.write(var);
            }
            if let Option::Some(var) = config_params.max_balance_per_vote {
                self.max_balance_per_vote.write(var);
            }
            if let Option::Some(var) = config_params.minimal_balance_create_proposal {
                self.minimal_balance_create_proposal.write(var);
            }
            if let Option::Some(var) = config_params.minimum_threshold_percentage {
                self.minimum_threshold_percentage.write(var);
            }
        }

        fn _get_config(self: @ContractState) -> ConfigResponse {
            ConfigResponse {
                is_admin_bypass_available: self.is_admin_bypass_available.read(),
                is_only_dao_execution: self.is_only_dao_execution.read(),
                token_contract_address: self.token_contract_address.read(),
                minimal_balance_voting: self.minimal_balance_voting.read(),
                max_balance_per_vote: self.max_balance_per_vote.read(),
                minimal_balance_create_proposal: self.minimal_balance_create_proposal.read(),
                minimum_threshold_percentage: self.minimum_threshold_percentage.read(),
            }
        }

        fn _resolve_proposal_calldata(ref self: ContractState, id: u256, calldata: Array<Call>) {
            let proposal_calldata = self.proposals_calldata.entry(id);

            for data in calldata {
                proposal_calldata.append().to.write(data.to);
                proposal_calldata.append().selector.write(data.selector);
                proposal_calldata.append().is_executed.write(false);

                for call in data
                    .calldata {
                        proposal_calldata.append().calldata.append().write(*call);
                    };

                self.proposal_tx.entry(id).append().write(data.hash_struct());
            };
        }
    }

    pub impl CallStructHash of StructHash<Call> {
        fn hash_struct(self: @Call) -> felt252 {
            let hash_state = PoseidonTrait::new();
            hash_state
                .update_with('AFK_DAO')
                .update_with(*self.to)
                .update_with(*self.selector)
                .update_with(poseidon_hash_span(*self.calldata))
                .finalize()
        }
    }
}

#[cfg(test)]
mod tests {
    use afk::interfaces::voting::{
        Proposal, ProposalParams, ProposalResult, ProposalType, UserVote, VoteState,
        ProposalCreated, SET_PROPOSAL_DURATION_IN_SECONDS, ProposalVoted, IVoteProposalDispatcher,
        IVoteProposalDispatcherTrait, ConfigParams, ConfigResponse, ProposalResolved,
    };
    use afk::tokens::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use core::num::traits::Zero;
    use openzeppelin::utils::serde::SerializedAppend;
    use snforge_std::{
        CheatSpan, ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, EventSpyTrait,
        EventsFilterTrait, cheat_caller_address, cheatcodes::events::Event, declare, spy_events,
        cheat_block_timestamp,
    };
    use starknet::account::Call;
    use starknet::{ContractAddress, contract_address_const};
    use super::{IDaoAADispatcher, IDaoAADispatcherTrait};
    use super::{ISRC6Dispatcher, ISRC6DispatcherTrait};


    /// UTILITY FUNCTIONS

    fn OWNER() -> ContractAddress {
        contract_address_const::<'OWNER'>()
    }

    fn CREATOR() -> ContractAddress {
        contract_address_const::<'CREATOR'>()
    }

    fn deploy_token() -> ContractAddress {
        let mut constructor_calldata = array![];
        let decimals = 10_u8;
        constructor_calldata.append_serde('DaoToken');
        constructor_calldata.append_serde('DAOO');
        constructor_calldata.append_serde(100000_u256);
        constructor_calldata.append_serde(OWNER());
        decimals.serialize(ref constructor_calldata);

        let contract = declare("ERC20").unwrap().contract_class();
        let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
        contract_address
    }

    fn deploy_dao(token_contract_address: ContractAddress) -> ContractAddress {
        let mut constructor_calldata = array![];
        let owner = OWNER();
        let public_key = 55555_u256;
        constructor_calldata.append_serde(owner);
        constructor_calldata.append_serde(token_contract_address);
        constructor_calldata.append_serde(public_key);
        constructor_calldata.append_serde('STARKNET ADDRESS');

        let contract = declare("DaoAA").unwrap().contract_class();
        let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

        contract_address
    }

    fn init_default_proposal(
        proposal_dispatcher: IVoteProposalDispatcher, created_at: u64,
    ) -> u256 {
        cheat_block_timestamp(
            proposal_dispatcher.contract_address, created_at, CheatSpan::TargetCalls(1),
        );
        cheat_caller_address(
            proposal_dispatcher.contract_address, CREATOR(), CheatSpan::TargetCalls(1),
        );
        let proposal_params = ProposalParams {
            content: "My Proposal",
            proposal_type: Default::default(),
            proposal_automated_transaction: Default::default(),
        };
        let calldata_1 = Call {
            to: contract_address_const::<'TO'>(),
            selector: 'selector',
            calldata: array!['data 1', 'data 2'].span()
        };

        let calldata_2 = Call {
            to: contract_address_const::<'ANOTHER'>(),
            selector: 'another selector',
            calldata: array!['data 3', 'data 4', 'data 5'].span()
        };
        // created by 'CREATOR'
        let proposal_id = proposal_dispatcher
            .create_proposal(proposal_params, array![calldata_1, calldata_2]);
        assert(!proposal_dispatcher.is_executable(calldata_1), '');
        assert(!proposal_dispatcher.is_executable(calldata_2), '');
        proposal_id
    }

    fn feign_executable_proposal(
        proposal_id: u256,
        proposal_dispatcher: IVoteProposalDispatcher,
        token_dispatcher: IERC20Dispatcher,
        creator: ContractAddress
    ) {
        let voter_1 = contract_address_const::<'VOTER 1'>();
        let voter_2 = contract_address_const::<'VOTER 2'>();
        let voter_3 = contract_address_const::<'VOTER 3'>();
        let voter_4 = contract_address_const::<'VOTER 4'>();

        let mut spy = spy_events();

        let voters = array![voter_1, voter_2, voter_3, voter_4];
        // cast two yes, one abstention, and one no
        // to prove abstention votes are not used when processing results at the moment,
        // the percentage outcome for validation here should be 66% (2/3) and not 50% (2/4)
        // so the proposal should pass
        let mut votes = array![UserVote::Yes, UserVote::Abstention, UserVote::No, UserVote::Yes];

        let created_at = starknet::get_block_timestamp();
        let mint_amount = 100;
        for voter in voters {
            cheat_caller_address(
                token_dispatcher.contract_address, OWNER(), CheatSpan::TargetCalls(1)
            );
            // mint
            let transferred = token_dispatcher.transfer(voter, mint_amount);
            assert(transferred, 'TOKEN TRANSFER ERROR');
            assert(token_dispatcher.balance_of(voter) == 100, 'BALANCE ERROR');
            // cast vote
            cheat_caller_address(
                proposal_dispatcher.contract_address, voter, CheatSpan::TargetCalls(1)
            );
            proposal_dispatcher.cast_vote(proposal_id, votes.pop_front());
        };

        let current_time = created_at
            + SET_PROPOSAL_DURATION_IN_SECONDS
            + 1; // Proposal duration reached
        cheat_block_timestamp(
            proposal_dispatcher.contract_address, current_time, CheatSpan::TargetCalls(1)
        );
        proposal_dispatcher.process_result(proposal_id);

        let expected_event = super::DaoAA::Event::ProposalResolved(
            ProposalResolved { id: proposal_id, owner: creator, result: ProposalResult::Passed },
        );

        spy.assert_emitted(@array![(proposal_dispatcher.contract_address, expected_event)]);
    }

    /// TESTS

    #[test]
    fn test_proposal_creation() {
        // snforge test afk::dao::dao_aa::tests::test_proposal_creation --exact
        let token_contract = deploy_token();
        let proposal_contract = deploy_dao(token_contract);
        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let caller = CREATOR();

        let created_at = starknet::get_block_timestamp();
        let end_at = created_at + SET_PROPOSAL_DURATION_IN_SECONDS;

        let mut spy = spy_events();

        let proposal_id = init_default_proposal(proposal_dispatcher, created_at);
        assert(proposal_id > 0, 'No proposal created');

        let creation_event = super::DaoAA::Event::ProposalCreated(
            ProposalCreated { id: proposal_id, owner: caller, created_at, end_at },
        );

        spy.assert_emitted(@array![(proposal_contract, creation_event)]);
    }

    #[test]
    fn test_proposal_vote_success() {
        // snforge test afk::dao::dao_aa::tests::test_proposal_vote_success --exact
        let voter = OWNER(); // minted with tokens
        let token_contract = deploy_token();
        let proposal_contract = deploy_dao(token_contract);
        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let token_dispatcher = IERC20Dispatcher { contract_address: token_contract };

        let voter_balance = token_dispatcher.balance_of(voter);
        assert(voter_balance > 0, 'MINT FAILED');

        let proposal_id = init_default_proposal(
            proposal_dispatcher, starknet::get_block_timestamp(),
        );

        let mut spy = spy_events();
        let voted_at = starknet::get_block_timestamp();
        cheat_block_timestamp(proposal_contract, voted_at, CheatSpan::TargetCalls(1));
        cheat_caller_address(proposal_contract, voter, CheatSpan::TargetCalls(1));
        proposal_dispatcher.cast_vote(proposal_id, Option::None); // should use a default then.

        let voted_event = super::DaoAA::Event::ProposalVoted(
            ProposalVoted {
                id: proposal_id,
                voter,
                vote: Default::default(),
                votes: voter_balance,
                total_votes: voter_balance,
                voted_at,
            },
        );

        spy.assert_emitted(@array![(proposal_contract, voted_event)]);
    }

    #[test]
    fn test_proposal_cancelation_success() {
        // snforge test afk::dao::dao_aa::tests::test_proposal_cancelation_success --exact
        let token_contract = deploy_token();
        let proposal_contract = deploy_dao(token_contract);
        let creator = CREATOR();

        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let proposal_id = init_default_proposal(
            proposal_dispatcher, starknet::get_block_timestamp(),
        );
        cheat_caller_address(proposal_contract, creator, CheatSpan::TargetCalls(1));
        proposal_dispatcher.cancel_proposal(proposal_id);

        let proposal = proposal_dispatcher.get_proposal(proposal_id);
        assert(proposal.proposal_result == ProposalResult::Canceled, 'CANCEL FAILED');
    }

    #[test]
    fn test_update_config_success() {
        // snforge test afk::dao::dao_aa::tests::test_update_config_success --exact
        let token_contract = contract_address_const::<'init'>();
        let proposal_contract = deploy_dao(token_contract);
        let dao_dispatcher = IDaoAADispatcher { contract_address: proposal_contract };

        let old_token_contract = dao_dispatcher.get_token_contract_address();
        assert(token_contract == old_token_contract, '');
        let new_token_contract = contract_address_const::<'new'>();
        let minimal_balance_voting = 5000;
        // change just two values
        cheat_caller_address(proposal_contract, OWNER(), CheatSpan::TargetCalls(1));
        let config_params = ConfigParams {
            is_admin_bypass_available: Option::None,
            // note: default is true, set in constructor. But we don't wish to change it.
            is_only_dao_execution: Option::None,
            token_contract_address: Option::Some(new_token_contract),
            minimal_balance_voting: Option::Some(minimal_balance_voting),
            max_balance_per_vote: Option::None,
            minimal_balance_create_proposal: Option::None,
            minimum_threshold_percentage: Option::None // 60 init in the contructor
        };

        dao_dispatcher.update_config(config_params);
        let config_response = dao_dispatcher.get_config();
        assert(
            config_response.is_only_dao_execution, 'UPDATE ERROR',
        ); // should return true, unchanged
        assert(config_response.token_contract_address == new_token_contract, 'TOKEN UPDATE ERROR');
        assert(
            config_response.minimal_balance_voting == minimal_balance_voting, 'VOTING UPDATE ERROR',
        );
    }

    #[test]
    #[should_panic(expected: 'PROPOSAL HAS ENDED')]
    fn test_proposal_should_panic_when_voted_on_upon_expiration() {
        // snforge test
        // afk::dao::dao_aa::tests::test_proposal_should_panic_when_voted_on_upon_expiration --exact
        let token_contract = deploy_token();
        let proposal_contract = deploy_dao(token_contract);
        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let voter = OWNER();

        let created_at = starknet::get_block_timestamp();
        let vote_at = created_at + SET_PROPOSAL_DURATION_IN_SECONDS + 1; // expiry + 1.
        let proposal_id = init_default_proposal(proposal_dispatcher, created_at);

        cheat_block_timestamp(proposal_contract, vote_at, CheatSpan::TargetCalls(1));
        cheat_caller_address(proposal_contract, voter, CheatSpan::TargetCalls(1));
        proposal_dispatcher.cast_vote(proposal_id, Option::None); // should panic
    }

    #[test]
    #[should_panic(expected: 'CANNOT VOTE ON PROPOSAL')]
    fn test_proposal_should_panic_when_voted_on_upon_cancelation() {
        // snforge test
        // afk::dao::dao_aa::tests::test_proposal_should_panic_when_voted_on_upon_cancelation
        // --exact
        let token_contract = deploy_token();
        let proposal_contract = deploy_dao(token_contract);
        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let voter = OWNER();

        let proposal_id = init_default_proposal(
            proposal_dispatcher, starknet::get_block_timestamp(),
        );
        cheat_caller_address(proposal_contract, CREATOR(), CheatSpan::TargetCalls(1));
        proposal_dispatcher.cancel_proposal(proposal_id);

        cheat_caller_address(proposal_contract, voter, CheatSpan::TargetCalls(1));
        proposal_dispatcher.cast_vote(proposal_id, Option::None);
    }

    #[test]
    #[should_panic(expected: 'INVALID PROPOSAL ID')]
    fn test_proposal_should_panic_with_nonexistent_id() {
        // snforge test
        // afk::dao::dao_aa::tests::test_proposal_should_panic_with_nonexistent_id --exact
        let proposal_contract = deploy_dao('token'.try_into().unwrap());
        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let _ = proposal_dispatcher.get_proposal(1);
    }

    #[test]
    #[should_panic(expected: 'CANNOT PROCESS PROPOSAL')]
    fn test_proposal_should_panic_when_processed_before_expiration() {
        let proposal_contract = deploy_dao('token'.try_into().unwrap());
        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let proposal_id = init_default_proposal(
            proposal_dispatcher, starknet::get_block_timestamp(),
        );
        proposal_dispatcher.process_result(proposal_id);
    }

    #[test]
    fn test_proposal_process_result_success() {
        // snforge test afk::dao::dao_aa::tests::test_proposal_process_result_success --exact
        let token_contract = deploy_token();
        let proposal_contract = deploy_dao(token_contract);
        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let token_dispatcher = IERC20Dispatcher { contract_address: token_contract };

        let created_at = starknet::get_block_timestamp();
        let proposal_id = init_default_proposal(proposal_dispatcher, created_at);

        feign_executable_proposal(proposal_id, proposal_dispatcher, token_dispatcher, CREATOR());

        let calldata_1 = Call {
            to: contract_address_const::<'TO'>(),
            selector: 'selector',
            calldata: array!['data 1', 'data 2'].span()
        };

        let calldata_2 = Call {
            to: contract_address_const::<'ANOTHER'>(),
            selector: 'another selector',
            calldata: array!['data 3', 'data 4', 'data 5'].span()
        };

        // non-existent calldata
        let calldata_3 = Call {
            to: contract_address_const::<'TO'>(),
            selector: 'another selector',
            calldata: array!['data 3', 'data 5'].span()
        };
        // the creating call should be executable
        assert(proposal_dispatcher.is_executable(calldata_1), '1 NOT EXECUTABLE');
        assert(proposal_dispatcher.is_executable(calldata_2), '2 NOT EXECUTABLE');

        // this should not be executable. it doesn't even exist.
        assert(!proposal_dispatcher.is_executable(calldata_3), 'INIT FAILED');
    }
    /// NOTE: WHEN THERE ARE FOUR (FOR EXAMPLE) IDENTICAL CALLDATA, ALL FOUR ARE EXECUTABLE, TRUE;
    /// BUT THE STORAGE HAS BEEN ENHANCED IN THAT IF ONLY THREE IDENTICAL CALLDATA ARE CAPTURED ON
    /// PROCESSING OF RESULTS, THE LAST __execute__ call WITH THE FOURTH IDENTITCAL CALLDATA WILL
    /// FAIL.
    /// ADDITIONAL CHECKS/ENHANCEMENT MAY BE ADDED IN THE FUTURE TO ACCOMMODATE CALLDATA THAT NEEDS
    /// RECURRING __execute__ calls.
    ///

    #[test]
    fn test_proposal_execution_success() {
        let token_contract = deploy_token();
        let proposal_contract = deploy_dao(token_contract);
        let token_dispatcher = IERC20Dispatcher { contract_address: token_contract };
        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let target_contract = contract_address_const::<'TARGET'>();

        assert(token_dispatcher.balance_of(target_contract) == 0, '');

        // initialize an executable proposal
        let created_at = starknet::get_block_timestamp();
        cheat_block_timestamp(
            proposal_dispatcher.contract_address, created_at, CheatSpan::TargetCalls(1),
        );
        cheat_caller_address(
            proposal_dispatcher.contract_address, OWNER(), CheatSpan::TargetCalls(1),
        );

        let proposal_params = ProposalParams {
            content: "My Proposal",
            proposal_type: Default::default(),
            proposal_automated_transaction: Default::default(),
        };

        let mut calldata = array![];
        let transfer_amount = 100_u256;
        target_contract.serialize(ref calldata);
        transfer_amount.serialize(ref calldata);

        let call = Call {
            to: token_contract, selector: selector!("transfer"), calldata: calldata.span()
        };

        // created by 'OWNER'
        let proposal_id = proposal_dispatcher.create_proposal(proposal_params, array![call]);
        assert(!proposal_dispatcher.is_executable(call), 'NOT EXECUTABLE');

        feign_executable_proposal(proposal_id, proposal_dispatcher, token_dispatcher, OWNER());
        let creator_balance = token_dispatcher.balance_of(OWNER());
        println!("Before call, owner balance: {}", creator_balance);

        let account_dispatcher = ISRC6Dispatcher { contract_address: proposal_contract };

        // __execute__ avoids calls from other contracts.
        cheat_caller_address(proposal_contract, Zero::zero(), CheatSpan::TargetCalls(1),);
        cheat_caller_address(token_contract, OWNER(), CheatSpan::Indefinite);
        let return_value = account_dispatcher.__execute__(array![call]);

        assert(token_dispatcher.balance_of(target_contract) == transfer_amount, 'EXECUTION FAILED');
        let current_creator_balance = creator_balance - transfer_amount;

        println!("Expected balance after execution: {}", current_creator_balance);
        assert(
            token_dispatcher.balance_of(OWNER()) == current_creator_balance, 'BALANCE NOT EQUAL'
        );
        let mut call_serialized_retval = *return_value.at(0);
        let call_retval = Serde::<bool>::deserialize(ref call_serialized_retval);
        assert!(call_retval.unwrap());

        // assert the call is no longer executable
        assert(!proposal_dispatcher.is_executable(call), 'STATE CHANGE FAILED');
    }

    #[test]
    #[should_panic(expected: 'CALL VALIDATION ERROR')]
    fn test_proposal_should_panic_on_invalid_call_execution() {
        let token_contract = deploy_token();
        let proposal_contract = deploy_dao(token_contract);

        let token_contract = deploy_token();
        let proposal_contract = deploy_dao(token_contract);
        let token_dispatcher = IERC20Dispatcher { contract_address: token_contract };
        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let target_contract = contract_address_const::<'TARGET'>();

        // initialize an executable proposal
        let created_at = starknet::get_block_timestamp();
        cheat_block_timestamp(
            proposal_dispatcher.contract_address, created_at, CheatSpan::TargetCalls(1),
        );
        cheat_caller_address(
            proposal_dispatcher.contract_address, OWNER(), CheatSpan::TargetCalls(1),
        );

        let proposal_params = ProposalParams {
            content: "My Proposal",
            proposal_type: Default::default(),
            proposal_automated_transaction: Default::default(),
        };

        let mut calldata = array![];
        let transfer_amount = 100_u256;
        target_contract.serialize(ref calldata);
        transfer_amount.serialize(ref calldata);

        let call = Call {
            to: token_contract, selector: selector!("transfer"), calldata: calldata.span()
        };

        // created by 'OWNER'
        let proposal_id = proposal_dispatcher.create_proposal(proposal_params, array![call]);

        feign_executable_proposal(proposal_id, proposal_dispatcher, token_dispatcher, OWNER());
        let creator_balance = token_dispatcher.balance_of(OWNER());
        println!("Before call, owner balance: {}", creator_balance);

        let account_dispatcher = ISRC6Dispatcher { contract_address: proposal_contract };

        // __execute__ avoids calls from other contracts.
        cheat_caller_address(proposal_contract, Zero::zero(), CheatSpan::TargetCalls(1));
        cheat_caller_address(token_contract, OWNER(), CheatSpan::Indefinite);
        let _ = account_dispatcher.__execute__(array![call]);

        assert(token_dispatcher.balance_of(target_contract) == transfer_amount, 'EXECUTION FAILED');

        // execute the same call. should panic because the call has already been executed.
        cheat_caller_address(proposal_contract, Zero::zero(), CheatSpan::TargetCalls(1));
        let _ = account_dispatcher.__execute__(array![call]);
    }

    #[test]
    #[should_panic]
    fn test_proposal_call_storage_not_updated_on_execution_failure() {
        let token_contract = deploy_token();
        let proposal_contract = deploy_dao(token_contract);
        let proposal_dispatcher = IVoteProposalDispatcher { contract_address: proposal_contract };
        let token_dispatcher = IERC20Dispatcher { contract_address: token_contract };

        ///
        let created_at = starknet::get_block_timestamp();
        cheat_caller_address(proposal_contract, CREATOR(), CheatSpan::TargetCalls(1),);
        let proposal_params = ProposalParams {
            content: "My Proposal",
            proposal_type: Default::default(),
            proposal_automated_transaction: Default::default(),
        };
        let calldata_1 = Call {
            to: token_contract,
            selector: selector!("balance_of"),
            calldata: array!['data 1', 'data 2'].span()
        };

        let calldata_2 = Call {
            to: token_contract,
            selector: selector!("balance_of"),
            calldata: array!['data 3', 'data 4', 'data 5'].span()
        };
        // created by 'CREATOR'
        let proposal_id = proposal_dispatcher
            .create_proposal(proposal_params, array![calldata_1, calldata_2]);
        assert(!proposal_dispatcher.is_executable(calldata_1), '');
        assert(!proposal_dispatcher.is_executable(calldata_2), '');
        ///

        feign_executable_proposal(proposal_id, proposal_dispatcher, token_dispatcher, CREATOR());
        let account_dispatcher = ISRC6Dispatcher { contract_address: proposal_contract };
        // assert these two are executable
        assert(proposal_dispatcher.is_executable(calldata_1), 'CALLDATA 1 NOT EXECUTABLE');
        assert(proposal_dispatcher.is_executable(calldata_2), 'CALLDATA 2 NOT EXECUTABLE');

        cheat_caller_address(proposal_contract, Zero::zero(), CheatSpan::TargetCalls(1));
        account_dispatcher.__execute__(array![calldata_1, calldata_2]);

        assert(proposal_dispatcher.is_executable(calldata_1), 'UDATE ERROR')
    }

    #[test]
    #[should_panic(expected: 'UNAUTHORIZED CALLER')]
    fn test_proposal_should_panic_on_config_update_unauthorized_caller() {
        let token_contract = contract_address_const::<'init'>();
        let proposal_contract = deploy_dao(token_contract);
        let dao_dispatcher = IDaoAADispatcher { contract_address: proposal_contract };

        let old_token_contract = dao_dispatcher.get_token_contract_address();
        assert(token_contract == old_token_contract, '');
        let new_token_contract = contract_address_const::<'new'>();
        let minimal_balance_voting = 5000;

        // change just two values. This change will be made by an unauthorized caller
        cheat_caller_address(proposal_contract, CREATOR(), CheatSpan::TargetCalls(1));
        let config_params = ConfigParams {
            is_admin_bypass_available: Option::None,
            // note: default is true, set in constructor. But we don't wish to change it.
            is_only_dao_execution: Option::None,
            token_contract_address: Option::Some(new_token_contract),
            minimal_balance_voting: Option::Some(minimal_balance_voting),
            max_balance_per_vote: Option::None,
            minimal_balance_create_proposal: Option::None,
            minimum_threshold_percentage: Option::None // 60 init in the contructor
        };

        dao_dispatcher.update_config(config_params); // should panic.
    }
}
