// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ByteHasher} from "./helpers/ByteHasher.sol";
import {IWorldID} from "./interfaces/IWorldID.sol";

interface IWilderr {
    /**********************  This section is for becoming the member of DAO *****************/

    // Note :- if anyone want to become member of DAO
    function registerInDAO(address candidate) external;

    // Note :- Members of DAO vote to make candidate member of DAO or not
    function voteForDaoMembership(address candidate) external;

    // Note :- make the candidate member of DAO if eligible after voting
    function make_DAO_member(uint256 _id) external;

    /*******************  This DAO section ends here **********************/

    //Note:- call by event-organiser for registering an event
    function registerEvent(string memory _uri) external;

    //Note:- Members of DAO vote to allow/not allow event
    function voteForEvent(uint256 id, bool _vote) external;

    //Note:- called by audienec to book their slot for the event , Uri contain info and face picture of attendee
    function registerForEvent(uint256 eventId, string memory uri) external;

    //Note:- attendee submit proof-Of-attendence for being eligible to get nft. uri contain a picture with host as a proof
    function submitProof(uint256 eventId, string memory uri) external;
}

error INVALID_CANDIDATE();

contract Wilderr is ERC721URIStorage {
    /*  *************************    DAO section starts here *************************** */

    // mapping(address=>bool) isDAO_member; // check is address is a member of DAO
    uint256 public totalDaoMembers; // total of number of DAO members
    uint256 public nextProposal = 1;

    struct DAO_Proposal {
        uint256 id;
        address candidate;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    enum DAO_membership_status {
        //Note:-check the status of someone applying to become member of DAO
        notApplied,
        applied,
        approved,
        rejected
    }
    mapping(uint256 => DAO_Proposal) public DAO_Proposals;
    mapping(address => DAO_membership_status)
        public DAO_membership_status_mapping; //check status of address in DAO

    constructor(address[] memory _Dao_member_array, IWorldID _worldId)
        ERC721("Wilderr", "WLD")
    {
        for (uint i = 0; i < _Dao_member_array.length; i++) {
            DAO_membership_status_mapping[
                _Dao_member_array[i]
            ] = DAO_membership_status.approved; // mark all addresses of array as DAO member
            totalDaoMembers += 1;
        }
        worldId = _worldId;
    }

    function registerInDAO(address _candidate) external {
        require(checkDAO_MembershipStatus(_candidate) == true);
        DAO_membership_status_mapping[_candidate] = DAO_membership_status
            .applied;
        DAO_Proposal storage proposal = DAO_Proposals[nextProposal];
        proposal.candidate = _candidate;
        proposal.id = nextProposal;
        proposal.deadline = block.timestamp + 1 days;

        //TODO emit event

        nextProposal++;
    }

    function voteForDaoMembership(uint256 _proposalId, bool _vote)
        external
        onlyDAO_member
    {
        DAO_Proposal storage proposal = DAO_Proposals[_proposalId];
        // voting can only happen before deadline
        require(block.timestamp <= proposal.deadline);
        // the candidate of this proposalId must have "applied" status only
        require(
            DAO_membership_status_mapping[proposal.candidate] ==
                DAO_membership_status.applied
        );
        // the DAO member voting must not have voted already
        require(proposal.voteStatus[msg.sender] == false, "cant vote twice");

        proposal.voteStatus[msg.sender] == true;
        if (_vote) {
            proposal.votesUp++;
        } else {
            proposal.votesDown++;
        }

        //TODO emit event
    }

    function make_DAO_member(uint256 _id) external onlyDAO_member {
        DAO_Proposal storage proposal = DAO_Proposals[_id];
        require(block.timestamp > proposal.deadline);
        // the candidate of this proposalId must have "applied" status only
        require(
            DAO_membership_status_mapping[proposal.candidate] ==
                DAO_membership_status.applied
        );

        if (proposal.votesUp > proposal.votesDown) {
            totalDaoMembers += 1;
            DAO_membership_status_mapping[
                proposal.candidate
            ] = DAO_membership_status.approved;
        } else {
            DAO_membership_status_mapping[
                proposal.candidate
            ] = DAO_membership_status.rejected;
        }

        //TODO emit event
    }

    function checkDAO_MembershipStatus(address _user)
        public
        view
        returns (bool)
    {
        if (
            _user != address(0) &&
            DAO_membership_status_mapping[_user] ==
            DAO_membership_status.notApplied
        ) {
            return true;
        }
        return false;
    }

    modifier onlyDAO_member() {
        require(
            DAO_membership_status_mapping[msg.sender] ==
                DAO_membership_status.approved
        );
        _;
    }

    /*  *************************    DAO section ends here *************************** */

    event event_proposed(uint256 indexed eventId, address indexed host);
    event voted_for_event(
        uint256 indexed eventId,
        bool indexed vote,
        address indexed voter
    );
    event event_registered(uint256 indexed eventId, address indexed host);
    event event_booked(uint256 indexed eventId, address indexed participant);
    event proof_submitted(uint256 indexed eventId, address indexed participant);
    event verified_participant(
        uint256 indexed eventId,
        address indexed participant
    );

    enum proposal_status {
        notProposed,
        proposed,
        approved,
        rejected
    }
    struct metadataOf_participant {
        bool registerdForEvent; // if user has registerd for event or not
        string participant_uri; // metadata about participant
        string proof; // proof submitted by participant after attending event
        bool eligible; // true if participant becomes eligible to mint nft
    }
    struct Event_proposal {
        uint256 id;
        string name;
        address host;
        string uri;
        uint256 maxAudience;
        uint256 currentAudienceCount;
        uint256 deadline; // it means DAO member cannot vote on this proposal after this deadline breaches
        uint256 eventTime;
        uint256 votesUp;
        uint256 votesDown;
        mapping(address => bool) voteStatus;
        proposal_status status;
    }
    uint256 public next_event_proposal = 1;
    uint256 public nftId = 1;
    mapping(uint256 => Event_proposal) public event_proposals;

    /*
    @author
    1.for a user participant_info[id][user].registerdForEvent is true if user has booked a slot in the event of id 'id'.
    2.participant_info[id][user].participant_uri contains metadata uri of a user(his face picture , name , address etc).
    */
    mapping(uint256 => mapping(address => metadataOf_participant))
        public participant_info;

    function registerEvent(
        string memory _uri,
        uint256 daysLeftForEvent,
        string memory eventName,
        uint256 _maxAudience
    ) external {
        require(daysLeftForEvent > 2); // register event before minimum 3 days before the event time
        Event_proposal storage proposal = event_proposals[next_event_proposal];
        proposal.id = next_event_proposal;
        proposal.status = proposal_status.proposed;
        proposal.name = eventName;
        proposal.uri = _uri;
        proposal.maxAudience = _maxAudience;
        proposal.deadline = block.timestamp + 2 days;
        proposal.eventTime = block.timestamp + daysLeftForEvent * 24 * 60 * 60;
        proposal.host = msg.sender;

        emit event_proposed(next_event_proposal, msg.sender);
        next_event_proposal++;
    }

    function voteForEvent(uint256 id, bool _vote) external onlyDAO_member {
        Event_proposal storage proposal = event_proposals[id];
        require(
            block.timestamp <= proposal.deadline &&
                proposal.status == proposal_status.proposed &&
                proposal.voteStatus[msg.sender] == false
        );

        proposal.voteStatus[msg.sender] = true;
        if (_vote) {
            proposal.votesUp++;
        } else {
            proposal.votesDown++;
        }

        emit voted_for_event(id, _vote, msg.sender);
    }

    // @author after DAO member has voted , if votesUp is more than votedDown of a proposal then that proposal is marked as "approved"
    function countVotes(uint256 id) external {
        Event_proposal storage proposal = event_proposals[id];
        require(
            block.timestamp > proposal.deadline &&
                proposal.status == proposal_status.proposed
        );

        if (proposal.votesUp > proposal.votesDown) {
            proposal.status = proposal_status.approved;
        } else {
            proposal.status = proposal_status.rejected;
        }

        emit event_registered(id, proposal.host);
    }

    //@notice:- this function is called by user to book slot in event
    function registerForEvent(
        uint256 eventId,
        string memory uri,
        address input,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        //Note:- here it verifes the person shouldn't have booked a slot already
        verifyAndExecute(input, root, nullifierHash, proof, eventId);

        Event_proposal storage proposal = event_proposals[eventId];
        metadataOf_participant memory participant = participant_info[eventId][
            msg.sender
        ];
        require(
            bytes(uri).length != 0 &&
                proposal.status == proposal_status.approved &&
                proposal.currentAudienceCount <= proposal.maxAudience
        );
        require(
            !participant.registerdForEvent &&
                bytes(participant.participant_uri).length == 0
        );

        proposal.currentAudienceCount++;
        participant.registerdForEvent = true;
        participant.participant_uri = uri;

        participant_info[eventId][msg.sender] = participant;

        emit event_booked(eventId, msg.sender);
    }

    function submitProof(uint256 eventId, string memory uri) external {
        Event_proposal storage proposal = event_proposals[eventId];
        metadataOf_participant memory participant = participant_info[eventId][
            msg.sender
        ];
        require(
            proposal.status == proposal_status.approved &&
                bytes(uri).length != 0
        ); // event must be approved
        require(
            participant.registerdForEvent == true &&
                bytes(participant.proof).length == 0
        ); // msg.sender must be registered in this event and shouldn't have submitted proof already
        require(block.timestamp > proposal.eventTime); // can only submit proof after the event is over.
        participant.proof = uri;
        participant_info[eventId][msg.sender] = participant;
        emit proof_submitted(eventId, msg.sender);
    }

    function verifyParticipants(
        uint256 eventId,
        address[] memory participant_array
    ) external {
        Event_proposal storage proposal = event_proposals[eventId];

        require(msg.sender == proposal.host); // only host can verify the participants
        for (uint i = 0; i < participant_array.length; i++) {
            metadataOf_participant memory participant = participant_info[
                eventId
            ][participant_array[i]];

            if (
                bytes(participant.proof).length != 0 &&
                participant.eligible == false
            ) {
                participant.eligible = true;
                emit verified_participant(eventId, participant_array[i]);
            }
            participant_info[eventId][participant_array[i]] = participant;
        }
    }

    function mintNft(uint eventId) external {
        metadataOf_participant memory participant = participant_info[eventId][
            msg.sender
        ];
        require(participant.eligible == true);

        _mint(msg.sender, nftId);
        _setTokenURI(nftId, participant.proof);
        nftId++;
    }

    /* ************** Getter functions ***************** */
    function getParticipantInfo(uint256 eventId, address user)
        external
        view
        returns (metadataOf_participant memory)
    {
        return participant_info[eventId][user];
    }

    /* *********************  Worldcoin verification section ********************** */

    using ByteHasher for bytes;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when attempting to reuse a nullifier
    // error InvalidNullifier();
    error InvalidUser();

    /// @dev The WorldID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The WorldID group ID (1)
    uint256 internal immutable groupId = 1;

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    // mapping(uint256 => bool) internal nullifierHashes; //Commented this out coz we need the verification for a single event and not for all events

    //Note:- this mapping checks that a user must book a single slot for a single event.
    mapping(uint256 => mapping(uint256 => bool)) public eventAttended;

    /// @param input User's input, used as the signal. Could be something else! (see README)
    /// @param root The of the Merkle tree, returned by the SDK.
    /// @param nullifierHash The nullifier for this proof, preventing double signaling, returned by the SDK.
    /// @param proof The zero knowledge proof that demostrates the claimer is registered with World ID, returned by the SDK.
    /// @dev Feel free to rename this method however you want! We've used `claim`, `verify` or `execute` in the past.
    function verifyAndExecute(
        address input,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof,
        uint256 eventId
    ) internal {
        // first, we make sure this person hasn't done this before
        // if (nullifierHashes[nullifierHash]) revert InvalidNullifier();
        if (eventAttended[eventId][nullifierHash]) revert InvalidUser();

        // then, we verify they're registered with WorldID, and the input they've provided is correct
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(input).hashToField(),
            nullifierHash,
            abi.encodePacked(address(this)).hashToField(),
            proof
        );

        // finally, we record they've done this, so they can't do it again (proof of uniqueness)
        // nullifierHashes[nullifierHash] = true;
        eventAttended[eventId][nullifierHash] = true;
        // eventAttended[eventId][nullifierHashes[nullifierHash]] = true;

        // your logic here, make sure to emit some kind of event afterwards!
    }
}
