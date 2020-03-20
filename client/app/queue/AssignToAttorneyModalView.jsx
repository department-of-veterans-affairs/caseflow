import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { AssignWidgetModal } from './components/AssignWidget';

import COPY from '../../COPY.json';

import {
  taskById
} from './selectors';

import {
  initialAssignTasksToUser,
  reassignTasksToUser
} from './QueueActions';

class AssignToAttorneyModalView extends React.PureComponent {
  handleAssignment = (
    { tasks, assigneeId }
  ) => {
    const previousAssigneeId = tasks[0].assignedTo.id.toString();

    if ([COPY.JUDGE_ASSIGN_TASK_LABEL, COPY.JUDGE_QUALITY_REVIEW_TASK_LABEL].includes(tasks[0].label)) {
      return this.props.initialAssignTasksToUser({
        tasks,
        assigneeId,
        previousAssigneeId
      });
    }

    return this.props.reassignTasksToUser({
      tasks,
      assigneeId,
      previousAssigneeId
    });
  }

  render = () => {
    const { task, userId, match } = this.props;
    const previousAssigneeId = task ? task.assignedTo.id.toString() : null;

    if (!previousAssigneeId) {
      return null;
    }

    return <AssignWidgetModal
      isModal
      match={match}
      userId={userId}
      onTaskAssignment={this.handleAssignment}
      previousAssigneeId={previousAssigneeId}
      selectedTasks={[task]} />;
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    task: taskById(state, { taskId: ownProps.match.params.taskId })
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  initialAssignTasksToUser,
  reassignTasksToUser
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(AssignToAttorneyModalView));
