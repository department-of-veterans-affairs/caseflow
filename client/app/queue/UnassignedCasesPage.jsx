import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import StatusMessage from '../components/StatusMessage';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
import {
  initialAssignTasksToUser
} from './QueueActions';
import AssignWidget from './components/AssignWidget';

const UnassignedCasesPage = (props) => {
  const { tasksAndAppeals: { length: reviewableCount }, userId, featureToggles } = props;
  let tableContent;

  if (reviewableCount === 0) {
    tableContent = <StatusMessage title="Tasks not found">
       Congratulations! You don't have any cases to assign.
    </StatusMessage>;
  } else {
    tableContent = <React.Fragment>
      <h2>Cases to Assign</h2>
      {featureToggles.judge_assign_cases &&
        <AssignWidget previousAssigneeId={userId}
          onTaskAssignment={(params) => props.initialAssignTasksToUser(params)} />}
      <JudgeAssignTaskTable {...props} />
    </React.Fragment>;
  }

  return tableContent;
};

const mapStateToProps = (state) => {
  const {
    queue: {
      attorneysOfJudge
    },
    ui: {
      featureToggles
    }
  } = state;

  return {
    attorneysOfJudge,
    featureToggles
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    initialAssignTasksToUser
  }, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(UnassignedCasesPage);
