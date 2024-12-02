import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';

import { AssignToAttorneyWidgetModal } from './components/AssignToAttorneyWidget';

import COPY from '../../COPY';

import {
  taskById
} from './selectors';

import {
  initialAssignTasksToUser,
  reassignTasksToUser,
  initialSpecialtyCaseTeamAssignTasksToUser,
  legacyReassignToAttorney
} from './QueueActions';

class AssignToAttorneyModalView extends React.PureComponent {
  handleAssignment = (
    { tasks, assigneeId, instructions }
  ) => {
    const previousAssigneeId = tasks[0].assignedTo.id.toString();
    const commonProps = {
      tasks,
      assigneeId,
      previousAssigneeId,
      instructions
    };

    if (tasks[0].type === 'LegacyAppealsAssignmentTrackingTask') {
      return this.props.legacyReassignToAttorney({ ...commonProps });
    }

    if (tasks[0].type === 'SpecialtyCaseTeamAssignTask') {
      return this.props.initialSpecialtyCaseTeamAssignTasksToUser({ ...commonProps });
    }

    if ([COPY.JUDGE_ASSIGN_TASK_LABEL, COPY.JUDGE_QUALITY_REVIEW_TASK_LABEL].includes(tasks[0].label)) {
      return this.props.initialAssignTasksToUser({ ...commonProps });
    }

    return this.props.reassignTasksToUser({ ...commonProps });
  }

  render = () => {
    const { task, userId, match } = this.props;
    const previousAssigneeId = task ? task.assignedTo.id.toString() : null;
    const sctModalProps = task.type === 'SpecialtyCaseTeamAssignTask' ?
      {
        selectedAssignee: 'OTHER',
        hidePrimaryAssignDropdown: true,
        secondaryAssignDropdownLabel: COPY.SPECIALTY_CASE_TEAM_ASSIGN_DROPDOWN_LABEL,
        pathAfterSubmit: '/organizations/specialty-case-team?tab=sct_action_required'
      } : {};

    if (!previousAssigneeId) {
      return null;
    }

    return <>
      <AssignToAttorneyWidgetModal
        isModal
        match={match}
        userId={userId}
        onTaskAssignment={this.handleAssignment}
        previousAssigneeId={previousAssigneeId}
        selectedTasks={[task]}
        {...sctModalProps}
      />
    </>;
  }
}

AssignToAttorneyModalView.propTypes = {
  task: PropTypes.shape({
    assignedTo: PropTypes.shape({
      id: PropTypes.number
    }),
    type: PropTypes.string
  }),
  userId: PropTypes.string,
  match: PropTypes.object,
  initialAssignTasksToUser: PropTypes.func,
  reassignTasksToUser: PropTypes.func,
  initialSpecialtyCaseTeamAssignTasksToUser: PropTypes.func,
  legacyReassignToAttorney: PropTypes.func
};

const mapStateToProps = (state, ownProps) => {
  return {
    task: taskById(state, { taskId: ownProps.match.params.taskId })
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  initialAssignTasksToUser,
  reassignTasksToUser,
  initialSpecialtyCaseTeamAssignTasksToUser,
  legacyReassignToAttorney
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(AssignToAttorneyModalView));
