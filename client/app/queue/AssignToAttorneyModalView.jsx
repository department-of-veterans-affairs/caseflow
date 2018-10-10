// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { AssignWidgetModal } from './components/AssignWidget';

import {
  tasksForAppealAssignedToAttorneySelector,
  tasksForAppealAssignedToUserSelector
} from './selectors';

import {
  initialAssignTasksToUser,
  reassignTasksToUser
} from './QueueActions';

import type { State } from './types/state';
import type { Task } from './types/models';

type Params = {|
  appealId: number
|};

type Props = Params & {|
  // From state
  task: Task,

  // From dispatch
  initialAssignTasksToUser: typeof initialAssignTasksToUser,
  reassignTasksToUser: typeof reassignTasksToUser
|};

class AssignToAttorneyModalView extends React.PureComponent<Props> {
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
    const previousAssigneeId = task ? task.assignedTo.id.toString() : null;

    if (!previousAssigneeId) {
      return null;
    }

    return <AssignWidgetModal
      isModal
      onTaskAssignment={this.handleAssignment}
      previousAssigneeId={previousAssigneeId}
      selectedTasks={[task]} />;
  }
}

const mapStateToProps = (state: State, ownProps: Object) => {
  return {
    task: tasksForAppealAssignedToAttorneySelector(state, ownProps)[0] ||
      tasksForAppealAssignedToUserSelector(state, ownProps)[0]
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  initialAssignTasksToUser,
  reassignTasksToUser
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(AssignToAttorneyModalView): React.ComponentType<Params>);
