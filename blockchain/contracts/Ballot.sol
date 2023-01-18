// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

import "./Types.sol";


contract Ballot {
    Types.Candidate[] public candidates;
    mapping(uint256 => Types.Voter) voter;
    mapping(uint256 => Types.Candidate) candidate;
    mapping(uint256 => uint256) internal votesCount;

    address electionChief;
    uint256 private votingStartTime;
    uint256 private votingEndTime;

    /**
     * @dev Create a new ballot to choose one of 'candidateNames'
     * @param startTime_ When the voting process will start
     * @param endTime_ When the voting process will end
     */
    constructor(uint256 startTime_, uint256 endTime_) {
        initializeCandidateDatabase_();
        initializeVoterDatabase_();
        votingStartTime = startTime_;
        votingEndTime = endTime_;
        electionChief = msg.sender;
    }

    /**
     * @dev Get candidate list.
     * @param voterNidNumber NID number of the current voter to send the relevent candidates list
     * @return candidatesList_ All the politicians who participate in the election
     */
    function getCandidateList(uint256 voterNidNumber)
        public
        view
        returns (Types.Candidate[] memory)
    {
        Types.Voter storage voter_ = voter[voterNidNumber];
        uint256 _politicianOfMyConstituencyLength = 0;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (
                voter_.stateCode == candidates[i].stateCode &&
                voter_.constituencyCode == candidates[i].constituencyCode
            ) _politicianOfMyConstituencyLength++;
        }
        Types.Candidate[] memory cc = new Types.Candidate[](
            _politicianOfMyConstituencyLength
        );

        uint256 _indx = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (
                voter_.stateCode == candidates[i].stateCode &&
                voter_.constituencyCode == candidates[i].constituencyCode
            ) {
                cc[_indx] = candidates[i];
                _indx++;
            }
        }
        return cc;
    }

    /**
     * @dev Get candidate list.
     * @param voterNidNumber NID number of the current voter to send the relevent candidates list
     * @return voterEligible_ Whether the voter with provided aadhar is eligible or not
     */
    function isVoterEligible(uint256 voterNidNumber)
        public
        view
        returns (bool voterEligible_)
    {
        Types.Voter storage voter_ = voter[voterNidNumber];
        if (voter_.age >= 18 && voter_.isAlive) voterEligible_ = true;
    }

    /**
     * @dev Know whether the voter casted their vote or not. If casted get candidate object.
     * @param voterNidNumber NID number of the current voter
     * @return userVoted_ Boolean value which gives whether current voter casted vote or not
     * @return candidate_ Candidate details to whom voter casted his/her vote
     */
    function didCurrentVoterVoted(uint256 voterNidNumber)
        public
        view
        returns (bool userVoted_, Types.Candidate memory candidate_)
    {
        userVoted_ = (voter[voterNidNumber].votedTo != 0);
        if (userVoted_)
            candidate_ = candidate[voter[voterNidNumber].votedTo];
    }

    /**
     * @dev Give your vote to candidate.
     * @param nominationNumber Nid Number of the candidate
     * @param voterNidNumber Nid Number of the voter to avoid re-entry
     * @param currentTime_ To check if the election has started or not
     */
    function vote(
        uint256 nominationNumber,
        uint256 voterNidNumber,
        uint256 currentTime_
    )
        public
        votingLinesAreOpen(currentTime_)
        isEligibleVote(voterNidNumber, nominationNumber)
    {
        // updating the current voter values
        voter[voterNidNumber].votedTo = nominationNumber;

        // updates the votes the politician
        uint256 voteCount_ = votesCount[nominationNumber];
        votesCount[nominationNumber] = voteCount_ + 1;
    }

    /**
     * @dev Gives ending epoch time of voting
     * @return endTime_ When the voting ends
     */
    function getVotingEndTime() public view returns (uint256 endTime_) {
        endTime_ = votingEndTime;
    }

    /**
     * @dev used to update the voting start & end times
     * @param startTime_ Start time that needs to be updated
     * @param currentTime_ Current time that needs to be updated
     */
    function updateVotingStartTime(uint256 startTime_, uint256 currentTime_)
        public
        isElectionChief
    {
        require(votingStartTime > currentTime_);
        votingStartTime = startTime_;
    }

    /**
     * @dev To extend the end of the voting
     * @param endTime_ End time that needs to be updated
     * @param currentTime_ Current time that needs to be updated
     */
    function extendVotingTime(uint256 endTime_, uint256 currentTime_)
        public
        isElectionChief
    {
        require(votingStartTime < currentTime_);
        require(votingEndTime > currentTime_);
        votingEndTime = endTime_;
    }

    /**
     * @dev sends all candidate list with their votes count
     * @param currentTime_ Current epoch time of length 10.
     * @return candidateList_ List of Candidate objects with votes count
     */
    function getResults(uint256 currentTime_)
        public
        view
        returns (Types.Results[] memory)
    {
        require(votingEndTime < currentTime_);
        Types.Results[] memory resultsList_ = new Types.Results[](
            candidates.length
        );
        for (uint256 i = 0; i < candidates.length; i++) {
            resultsList_[i] = Types.Results({
                name: candidates[i].name,
                partyShortcut: candidates[i].partyShortcut,
                partyFlag: candidates[i].partyFlag,
                nominationNumber: candidates[i].nominationNumber,
                stateCode: candidates[i].stateCode,
                constituencyCode: candidates[i].constituencyCode,
                voteCount: votesCount[candidates[i].nominationNumber]
            });
        }
        return resultsList_;
    }

    /**
     * @notice To check if the voter's age is greater than or equal to 18
     * @param currentTime_ Current epoch time of the voter
     */
    modifier votingLinesAreOpen(uint256 currentTime_) {
        require(currentTime_ >= votingStartTime);
        require(currentTime_ <= votingEndTime);
        _;
    }

    /**
     * @notice To check if the voter's age is greater than or equal to 18
     * @param voterNid_ Nid number of the current voter
     * @param nominationNumber_ Nomination number of the candidate
     */
    modifier isEligibleVote(uint256 voterNid_, uint256 nominationNumber_) {
        Types.Voter memory voter_ = voter[voterNid_];
        Types.Candidate memory politician_ = candidate[nominationNumber_];
        require(voter_.age >= 18);
        require(voter_.isAlive);
        require(voter_.votedTo == 0);
        require(
            (politician_.stateCode == voter_.stateCode &&
                politician_.constituencyCode == voter_.constituencyCode)
        );
        _;
    }

    /**
     * @notice To check if the user is Election Chief or not
     */
    modifier isElectionChief() {
        require(msg.sender == electionChief);
        _;
    }

    /**
     * Dummy data for Candidates
     * In the future, we can accept the same from construction,
     * which will be called at the time of deployment
     */
    function initializeCandidateDatabase_() internal {
        Types.Candidate[] memory candidates_ = new Types.Candidate[](14);

        // Andhra Pradesh
        candidates_[0] = Types.Candidate({
            name: "Hirok Raja",
            partyShortcut: "TDP",
            partyFlag: "https://www.albd.org/static/images/logo-en.png",
            nominationNumber: uint256(727477314982),
            stateCode: uint8(10),
            constituencyCode: uint8(1)
        });
        candidates_[1] = Types.Candidate({
            name: "Oniket Prantor",
            partyShortcut: "YSRCP",
            partyFlag: "https://www.albd.org/static/images/logo-en.png",
            nominationNumber: uint256(835343722350),
            stateCode: uint8(10),
            constituencyCode: uint8(1)
        });
        candidates_[2] = Types.Candidate({
            name: "Avengers",
            partyShortcut: "TDP",
            partyFlag: "https://www.albd.org/static/images/logo-en.png",
            nominationNumber: uint256(969039304119),
            stateCode: uint8(10),
            constituencyCode: uint8(2)
        });
        
        for (uint256 i = 0; i < candidates_.length; i++) {
            candidate[candidates_[i].nominationNumber] = candidates_[i];
            candidates.push(candidates_[i]);
        }
    }

    /**
     * Dummy data for Nid users
     * In the future, we can have a an external API call to centralized aadhar DB
     * https://ethereum.stackexchange.com/a/334
     * https://docs.chain.link/docs/make-a-http-get-request/
     */
    function initializeVoterDatabase_() internal {
       
        voter[uint256(760344621247)] = Types.Voter({
            name: "Sabbir",
            nidNumber: uint256(760344621247),
            age: uint8(42),
            stateCode: uint8(10),
            constituencyCode: uint8(2),
            isAlive: true,
            votedTo: uint256(0)
        });
        // Bihar
        voter[uint256(908704156902)] = Types.Voter({
            name: "Rishikesh Das",
            nidNumber: uint256(908704156902),
            age: uint8(25),
            stateCode: uint8(11),
            constituencyCode: uint8(1),
            isAlive: true,
            votedTo: uint256(0)
        });
        voter[uint256(778925466180)] = Types.Voter({
            name: "K.A Mukit",
            nidNumber: uint256(778925466180),
            age: uint8(37),
            stateCode: uint8(11),
            constituencyCode: uint8(1),
            isAlive: true,
            votedTo: uint256(0)
        });
        voter[uint256(393071790055)] = Types.Voter({
            name: "Amirul Ifty",
            nidNumber: uint256(393071790055),
            age: uint8(29),
            stateCode: uint8(11),
            constituencyCode: uint8(2),
            isAlive: true,
            votedTo: uint256(0)
        });
        
    }
}
