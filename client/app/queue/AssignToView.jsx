// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import COPY from '../../COPY.json';

import {
  taskById,
  appealWithDetailSelector
} from './selectors';

import { onReceiveAmaTasks } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import TextareaField from '../components/TextareaField';

import editModalBase from './components/EditModalBase';
import {
  requestPatch,
  requestSave
} from './uiReducer/uiActions';

import { taskActionData } from './utils';

import type { State } from './types/state';
import type { Appeal, Task } from './types/models';

type Params = {|
  appealId: string,
  taskId: string,
  task: Task,
  isReassignAction: boolean,
  isTeamAssign: boolean,
  returnToCaseDetails: boolean,
  assigneeAlreadySelected: boolean,
  history: Object
|};

type Props = Params & {|
  appeal: Appeal,
  highlightFormItems: boolean,
  requestPatch: typeof requestPatch,
  requestSave: typeof requestSave,
  onReceiveAmaTasks: typeof onReceiveAmaTasks
|};

type ViewState = {|
  selectedValue: ?string,
  instructions: ?string
|};

const selectedAction = (props) => {
  const actionData = taskActionData(props);

  return actionData.selected ? actionData.options.find((option) => option.value === actionData.selected.id) : null;
};

class AssignToView extends React.Component<Props, ViewState> {
  constructor(props) {
    super(props);

    // Autofill the instruction field if assigning to a person on the team. Since they will
    // probably want the instructions from the assigner.
    const instructions = this.props.task.instructions;
    const instructionLength = instructions ? instructions.length : 0;
    let existingInstructions = '';

    if (instructions && instructionLength > 0 && !this.props.isTeamAssign && !this.props.isReassignAction) {
      existingInstructions = instructions[instructionLength - 1];
    }

    const action = selectedAction(this.props);

    this.state = {
      selectedValue: action ? action.value : null,
      instructions: existingInstructions
    };
  }

  validateForm = () => {
    return this.state.selectedValue !== null && this.state.instructions !== '';
  }

  submit = () => {
    const {
      appeal,
      task,
      isReassignAction,
      isTeamAssign
    } = this.props;

    const payload = {
      data: {
        tasks: [{
          type: taskActionData(this.props).type ? taskActionData(this.props).type : 'GenericTask',
          external_id: appeal.externalId,
          parent_id: task.taskId,
          assigned_to_id: this.state.selectedValue,
          assigned_to_type: isTeamAssign ? 'Organization' : 'User',
          instructions: this.state.instructions
        }]
      }
    };

    const successMsg = {
      title: sprintf(COPY.ASSIGN_TASK_SUCCESS_MESSAGE, this.getAssignee()),
      detail: taskActionData(this.props).message_detail
    };

    if (isReassignAction) {
      return this.reassignTask();
    }

    return this.props.requestSave('/tasks', payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  getAssignee = () => {
    let assignee = 'person';

    taskActionData(this.props).options.forEach((opt) => {
      if (opt.value === this.state.selectedValue) {
        assignee = opt.label;
      }
    });

    return assignee;
  }

  reassignTask = () => {
    const task = this.props.task;
    const payload = {
      data: {
        task: {
          reassign: {
            assigned_to_id: this.state.selectedValue,
            assigned_to_type: 'User',
            instructions: this.state.instructions
          }
        }
      }
    };

    const successMsg = { title: `Task reassigned to ${this.getAssignee()}` };

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      });
  }

  render = () => {
    const {
      assigneeAlreadySelected,
      highlightFormItems,
      task
    } = this.props;

    if (!task || task.availableActions.length === 0) {
      return null;
    }

    return <React.Fragment>
      { !assigneeAlreadySelected && <React.Fragment>
        <SearchableDropdown
          name="Assign to selector"
          searchable
          hideLabel
          errorMessage={highlightFormItems && !this.state.selectedValue ? 'Choose one' : null}
          placeholder={this.props.isTeamAssign ? COPY.ASSIGN_TO_TEAM_DROPDOWN : COPY.ASSIGN_TO_USER_DROPDOWN}
          value={this.state.selectedValue}
          onChange={(option) => this.setState({ selectedValue: option ? option.value : null })}
          options={taskActionData(this.props).options} />
        <br />
      </React.Fragment> }
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
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  requestSave,
  onReceiveAmaTasks
}, dispatch);

const propsToText = (props) => {
  // I think the editModalBase higher order component is still calling this after all of the actions have run and the
  // task's available actions have been updated to reflect the updated status of the task.
  const action = props.task && props.task.availableActions.length > 0 ? selectedAction(props) : null;
  const title = (props.assigneeAlreadySelected && action) ?
    sprintf(COPY.ASSIGN_TASK_TO_TITLE, action.label) :
    COPY.ASSIGN_TASK_TITLE;
  const actionData = taskActionData(props);
  const pathAfterSubmit = (actionData && actionData.redirect_after) || '/queue';

  return {
    title,
    pathAfterSubmit
  };
};

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(
  editModalBase(AssignToView, { propsToText })
)): React.ComponentType<Params>);
