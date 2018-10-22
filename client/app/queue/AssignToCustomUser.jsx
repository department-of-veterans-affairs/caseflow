// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import COPY from '../../COPY.json';

import {
  appealWithDetailSelector,
  tasksForAppealAssignedToUserSelector,
  incompleteOrganizationTasksByAssigneeIdSelector
} from './selectors';

import { setTaskAttrs } from './QueueActions';

import TextareaField from '../components/TextareaField';

import editModalBase from './components/EditModalBase';
import {
  requestPatch,
  requestSave
} from './uiReducer/uiActions';

import TASK_ACTIONS from '../../constants/TASK_ACTIONS.json';

import type { State } from './types/state';
import type { Appeal, Task } from './types/models';

type Params = {|
  appealId: string,
  task: Task,
  isReassignAction: boolean,
  isTeamAssign: boolean
|};

type Props = Params & {|
  appeal: Appeal,
  highlightFormItems: boolean,
  requestPatch: typeof requestPatch,
  requestSave: typeof requestSave,
  setTaskAttrs: typeof setTaskAttrs
|};

type ViewState = {|
  instructions: ?string
|};

class AssignToCustomUser extends React.Component<Props, ViewState> {
  constructor(props) {
    super(props);

    this.state = {
      instructions: ''
    };
  }

  validateForm = () => {
    return this.state.instructions !== '';
  }

  submit = () => {
    const {
      appeal,
      task
    } = this.props;
    const payload = {
      data: {
        tasks: [{
          type: this.taskActionData().type,
          external_id: appeal.externalId,
          parent_id: task.taskId,
          assigned_to_id: this.taskActionData().user.id,
          assigned_to_type: 'User',
          instructions: this.state.instructions
        }]
      }
    };

    const successMsg = { title: `Task assigned to ${this.taskActionData().user.full_name}` };

    return this.props.requestSave('/tasks', payload, successMsg).
      then(() => {
        this.props.setTaskAttrs(task.uniqueId, { status: 'on_hold' });
      });
  }

  taskActionData = () : { user: Object, type: string } => {
    const action = this.props.task.availableActions.
      find((action) => action.value === TASK_ACTIONS.RETURN_TO_JUDGE.value);

    if (action && action.data) {
      return (action.data);
    }

    throw 'Action missing data';
  }

  render = () => {
    const {
      highlightFormItems
    } = this.props;

    return <React.Fragment>
      Assign task to {this.taskActionData().user.full_name}
      <TextareaField
        name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
        errorMessage={highlightFormItems && !this.state.instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
        id="taskInstructions"
        onChange={(value) => this.setState({ instructions: value })}
        value={this.state.instructions} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const {
    highlightFormItems
  } = state.ui;

  return {
    highlightFormItems,
    task: tasksForAppealAssignedToUserSelector(state, { appealId: ownProps.appealId })[0] ||
      incompleteOrganizationTasksByAssigneeIdSelector(state, { appealId: ownProps.appealId })[0],
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  requestSave,
  setTaskAttrs
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(
  editModalBase(AssignToCustomUser, { title: COPY.ASSIGN_TO_PAGE_TITLE })
)): React.ComponentType<Params>);
