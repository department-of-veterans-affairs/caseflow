// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { AssignWidgetModal } from './components/AssignWidget';

import {
  taskById
} from './selectors';

import {
  returnCaseToAttorney
} from './QueueActions';

import type { State } from './types/state';
import type { Task } from './types/models';

type Params = {|
  appealId: number,
  userId: string,
  taskId: number
|};

type Props = Params & {|
  // From state
  task: Task,

  // From dispatch
  returnCaseToAttorney: typeof returnCaseToAttorney
|};

class ReturnToAttorneyModalView extends React.PureComponent<Props> {
  handleAssignment = (
    { tasks, assigneeId }: { tasks: Array<Task>, assigneeId: string }
  ) => {
    const previousAssigneeId = tasks[0].assignedTo.id.toString();

    return this.props.returnCaseToAttorney({
      tasks,
      assigneeId,
      previousAssigneeId
    });
  }

  render = () => {
    const { task, userId } = this.props;
    const previousAssigneeId = task ? task.assignedTo.id.toString() : null;

    if (!previousAssigneeId) {
      return null;
    }

    return <AssignWidgetModal
      isModal
      userId={userId}
      onTaskAssignment={this.handleAssignment}
      previousAssigneeId={previousAssigneeId}
      selectedTasks={[task]}
      assignedVerb="Returned" />;
  }
}

const mapStateToProps = (state: State, ownProps: Object) => {
  return {
    task: taskById(state, { taskId: ownProps.taskId })
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  returnCaseToAttorney
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(ReturnToAttorneyModalView): React.ComponentType<Props>);
