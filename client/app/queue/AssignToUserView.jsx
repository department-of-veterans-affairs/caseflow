// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import COPY from '../../COPY.json';

import {
  appealWithDetailSelector
} from './selectors';
import { setAppealAod } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import editModalBase from './components/EditModalBase';
import { AssignWidgetModal } from './components/AssignWidget';
import { requestSave } from './uiReducer/uiActions';

import {
  tasksForAppealAssignedToAttorneySelector,
  tasksForAppealAssignedToUserSelector
} from './selectors';

import {
  initialAssignTasksToUser,
  reassignTasksToUser
} from './QueueActions';


import type { State } from './types/state';
import type { Appeal } from './types/models';

class AssignToUserView extends React.PureComponent<Props> {
  handleAssignment = (
    { tasks, assigneeId }: { tasks: Array<Task>, assigneeId: string }
  ) => {
    const previousAssigneeId = tasks[0].assignedTo.id.toString();

    if (tasks[0].action === 'assign') {
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
    const { task } = this.props;

    return <AssignWidgetModal
      onTaskAssignment={this.handleAssignment}
      previousAssigneeId={task.assignedTo.id.toString()}
      selectedTasks={[task]} />;
  }
}

const mapStateToProps = (state: State, ownProps: Object) => {
  const one = tasksForAppealAssignedToAttorneySelector(state, ownProps)[0];
  const two = tasksForAppealAssignedToUserSelector(state, ownProps)[0];
  return {
    task: one || two
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  initialAssignTasksToUser,
  reassignTasksToUser
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(AssignToUserView): React.ComponentType<Params>);
