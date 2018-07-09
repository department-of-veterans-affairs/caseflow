import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
import {
  initialAssignTasksToUser
} from './QueueActions';
import AssignWidget from './components/AssignWidget';

const UnassignedCasesPage = (props) => {
  const { userId, featureToggles } = props;

  return <React.Fragment>
    <h2>Cases to Assign</h2>
    {featureToggles.judge_assign_cases &&
      <AssignWidget previousAssigneeId={userId}
        onTaskAssignment={(params) => props.initialAssignTasksToUser(params)} />}
    <JudgeAssignTaskTable {...props} />
  </React.Fragment>;
};

const mapStateToProps = (state) => {
  const {
    ui: {
      featureToggles
    }
  } = state;

  return {
    featureToggles
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    initialAssignTasksToUser
  }, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(UnassignedCasesPage);
