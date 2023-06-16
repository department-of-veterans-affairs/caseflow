import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';

import { AssignToAttorneyLegacyWidgetModal } from './components/AssignToAttorneyLegacyWidget';
import COPY from '../../COPY';

import {
  taskById
} from './selectors';

import {
  initialAssignTasksToUser,
  reassignTasksToUser,
  legacyReassignToJudgeAttorney
} from './QueueActions';

class AssignToAttorneyLegacyModalView extends React.PureComponent {
  handleAssignment = (
    { tasks, assigneeId, instructions }
  ) => {
    const previousAssigneeId = tasks[0].assignedTo.id.toString();

    if ([COPY.JUDGE_ASSIGN_TASK_LABEL, COPY.JUDGE_QUALITY_REVIEW_TASK_LABEL].includes(tasks[0].label)) {
      return this.props.initialAssignTasksToUser({
        tasks,
        assigneeId,
        previousAssigneeId,
        instructions
      }).then(() => {
        if (tasks[0].appealType === 'LegacyAppeal') {
          this.props.legacyReassignToJudgeAttorney({
            tasks,
            assigneeId
          });
        }
      });
    }

    return this.props.reassignTasksToUser({
      tasks,
      assigneeId,
      previousAssigneeId,
      instructions
    }).then(() => {
      if (tasks[0].appealType === 'LegacyAppeal') {
        this.props.legacyReassignToJudgeAttorney({
          tasks,
          assigneeId
        });
      }
    });
  }

  render = () => {
    const { task, userId, match } = this.props;
    const previousAssigneeId = task ? task.assignedTo.id.toString() : null;

    if (!previousAssigneeId) {
      return null;
    }

    return (<AssignToAttorneyLegacyWidgetModal
      isModal
      match={match}
      userId={userId}
      onTaskAssignment={this.handleAssignment}
      previousAssigneeId={previousAssigneeId}
      selectedTasks={[task]} />);
  }
}

AssignToAttorneyLegacyModalView.propTypes = {
  task: PropTypes.shape({
    assignedTo: PropTypes.shape({
      id: PropTypes.number
    })
  }),
  userId: PropTypes.string,
  match: PropTypes.object,
  initialAssignTasksToUser: PropTypes.func,
  reassignTasksToUser: PropTypes.func,
  legacyReassignToJudgeAttorney: PropTypes.func
};

const mapStateToProps = (state, ownProps) => {
  return {
    task: taskById(state, { taskId: ownProps.match.params.taskId })
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  initialAssignTasksToUser,
  reassignTasksToUser,
  legacyReassignToJudgeAttorney
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(AssignToAttorneyLegacyModalView));
