// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import _ from 'lodash';

import COPY from '../../COPY.json';

import {
  appealWithDetailSelector,
  tasksForAppealAssignedToUserSelector,
  incompleteOrganizationTasksByAssigneeIdSelector
} from './selectors';
import { prepareTasksForStore } from './utils';

import { setTaskAttrs } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import TextareaField from '../components/TextareaField';

import editModalBase from './components/EditModalBase';
import {
  requestPatch,
  requestSave
} from './uiReducer/uiActions';

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
  selectedValue: ?string,
  instructions: ?string
|};

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

    this.state = {
      selectedValue: null,
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
          type: 'GenericTask',
          external_id: appeal.externalId,
          parent_id: task.taskId,
          assigned_to_id: this.state.selectedValue,
          assigned_to_type: isTeamAssign ? 'Organization' : 'User',
          instructions: this.state.instructions
        }]
      }
    };

    const successMsg = { title: `Task assigned to ${this.getAssignee()}` };

    if (isReassignAction) {
      return this.reassignTask();
    }

    return this.props.requestSave('/tasks', payload, successMsg).
      then(() => {
        this.props.setTaskAttrs(task.uniqueId, { status: 'on_hold' });
      });
  }

  getAssignee = () => {
    let assignee = 'person';

    this.options().forEach((opt) => {
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
        const preparedTasks = prepareTasksForStore(response.tasks.data);

        _.map(preparedTasks, (preparedTask) => this.props.setTaskAttrs(preparedTask.uniqueId, preparedTask));
      });
  }

  options = () => {
    if (this.props.isTeamAssign) {
      return (this.props.task.assignableOrganizations || []).map((organization) => {
        return {
          label: organization.name,
          value: organization.id
        };
      });
    }

    return (this.props.task.assignableUsers || []).map((user) => {
      return {
        label: user.full_name,
        value: user.id
      };
    });
  }

  render = () => {
    const {
      highlightFormItems
    } = this.props;

    return <React.Fragment>
      <SearchableDropdown
        name="Assign to selector"
        searchable
        hideLabel
        errorMessage={highlightFormItems && !this.state.selectedValue ? 'Choose one' : null}
        placeholder={this.props.isTeamAssign ? COPY.ASSIGN_TO_TEAM_DROPDOWN : COPY.ASSIGN_TO_USER_DROPDOWN}
        value={this.state.selectedValue}
        onChange={(option) => this.setState({ selectedValue: option ? option.value : null })}
        options={this.options()} />
      <br />
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
  editModalBase(AssignToView, COPY.ASSIGN_TO_PAGE_TITLE)
)): React.ComponentType<Params>);
