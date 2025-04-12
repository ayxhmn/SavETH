// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SavETH - A goal based micro-savings smart contract
 * @author ayxhmn
 * @notice Users can create multiple ETH savings goals and withdraw only after reaching targets
 */
contract SavingsVault {

    /////////////////////////////////////////////
    //               ERRORS                   //
    ///////////////////////////////////////////
    error SavingsVault__TargetMustBeGreaterThanZero();
    error SavingsVault__TargetNotYetReached();
    error SavingsVault__TargetAlreadyReached();
    error SavingsVault__GoalDoesNotExist();

    /////////////////////////////////////////////
    //            STATE VARIABLES             //
    ///////////////////////////////////////////

    /// @notice A single savings goal with metadata
    struct Goal {
        uint256 targetAmount;
        uint256 amountSaved;
        bool targetReached;
        string name;
        string description;
    }

    /// @notice Mapping from user address to their goals
    mapping(address => mapping(uint256 => Goal)) public s_userGoals;

    /// @notice Number of goals created by a user
    mapping(address => uint256) public s_goalCount;

    /// @notice Optional username set by users
    mapping(address => string) public s_userNames;


    /////////////////////////////////////////////
    //               EVENTS                   //
    ///////////////////////////////////////////

    event GoalCreated(address indexed user, uint256 goalId, uint256 targetAmount, string name, string description);
    event Deposited(address indexed user, uint256 goalId, uint256 amount);
    event Withdrawn(address indexed user, uint256 goalId, uint256 amount);
    event UsernameSet(address indexed user, string name);


    /////////////////////////////////////////////
    //              FUNCTIONS                 //
    ///////////////////////////////////////////
    
    /**
     * @notice Create a new savings goal
     * @param _targetAmount The amount of ETH needed to complete the goal
     * @param _name A short name for the goal (e.g., "Laptop")
     * @param _description A longer description of the goal
     */
    function createGoal(uint256 _targetAmount, string calldata _name, string calldata _description) external {
        if (_targetAmount <= 0) {
            revert SavingsVault__TargetMustBeGreaterThanZero();
        }

        uint256 newGoalId = s_goalCount[msg.sender];
        s_userGoals[msg.sender][newGoalId] = Goal({
            targetAmount: _targetAmount,
            amountSaved: 0,
            targetReached: false,
            name: _name,
            description: _description
        });

        s_goalCount[msg.sender]++;
        emit GoalCreated(msg.sender, newGoalId, _targetAmount, _name, _description);
    }

    /**
     * @notice Deposit ETH into a specific savings goal
     * @param _goalId The ID of the goal to deposit into
     */
    function deposit(uint256 _goalId) external payable {
        Goal storage goal = s_userGoals[msg.sender][_goalId];
        if (goal.targetAmount == 0) {
            revert SavingsVault__GoalDoesNotExist();
        }
        if (goal.targetReached) {
            revert SavingsVault__TargetAlreadyReached();
        }

        goal.amountSaved += msg.value;

        if (goal.amountSaved >= goal.targetAmount) {
            goal.targetReached = true;
        }

        emit Deposited(msg.sender, _goalId, msg.value);
    }

    /**
     * @notice Withdraw ETH from a completed goal
     * @param _goalId The ID of the goal to withdraw from
     */
    function withdraw(uint256 _goalId) external {
        Goal storage goal = s_userGoals[msg.sender][_goalId];
        if (!goal.targetReached) {
            revert SavingsVault__TargetNotYetReached();
        }

        uint256 amount = goal.amountSaved;
        goal.amountSaved = 0;
        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, _goalId, amount);
    }

    /**
     * @notice Set a public username (optional)
     * @param _username The name to associate with the caller
     */
    function setUsername(string calldata _username) external {
        s_userNames[msg.sender] = _username;

        emit UsernameSet(msg.sender, _username);
    }


    /////////////////////////////////////////////
    //           GETTER FUNCTIONS             //
    ///////////////////////////////////////////

    /**
     * @notice Fetch a specific goal by user and goal ID
     * @param user The address of the goal owner
     * @param goalId The ID of the goal to fetch
     * @return A `Goal` struct containing goal details
     */
    function getGoal(address user, uint256 goalId) external view returns (Goal memory) {
        return s_userGoals[user][goalId];
    }

    /**
     * @notice Fetch all the goals of a user
     * @param user The address of user whose goals to get
     */
    function getAllGoals(address user) external view returns (Goal[] memory) {
        uint256 count = s_goalCount[user];
        Goal[] memory goals = new Goal[](count);
        for (uint256 i = 0; i < count; i++) {
            goals[i] = s_userGoals[user][i];
        }
        return goals;
    }

    /**
     * @notice Fetch the username set by a user
     * @param user The address of user whose username to get
     */
    function getUsername(address user) external view returns (string memory) {
        return s_userNames[user];
    }
}