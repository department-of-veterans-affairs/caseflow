import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import { taskActionData } from './utils';
import { sprintf } from 'sprintf-js';

import { AssignToAttorneyLegacyWidgetModal } from './components/AssignToAttorneyLegacyWidget';
import { taskById } from './selectors';
import COPY from '../../COPY';

import {
  initialAssignTasksToUser,
  reassignTasksToUser,
  legacyReassignToJudgeAttorney
} from './QueueActions';

class AssignToAttorneyLegacyModalView extends React.PureComponent {
  handleAssignment = (
    { tasks, assigneeId, instructions, assignee }
  ) => {
    const previousAssigneeId = tasks[0].assignedTo.id.toString();
    const previousAssignee = tasks[0].assigneeName;

    const assignTaskSuccessMessage = {
      title: taskActionData(this.props).message_title ? sprintf(taskActionData(this.props).message_title,
        previousAssignee,
        assignee) : sprintf(COPY.ASSIGN_TASK_SUCCESS_MESSAGE, this.getAssignee()),
      detail: taskActionData(this.props).message_detail || null
    };

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
          }, assignTaskSuccessMessage);
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
        }, assignTaskSuccessMessage);
      }
    });
  }

  getAssignee = () => {
    let assignee = 'person';

    taskActionData(this.props).options.forEach((opt) => {
      if (opt.value === this.state.selectedValue) {
        assignee = opt.label;
      }
    });
    const splitAssignee = assignee.split(' ');

    if (splitAssignee.length >= 3) {
      assignee = `${splitAssignee[0] } ${ splitAssignee[2]}`;
    }

    return assignee;
  };

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
