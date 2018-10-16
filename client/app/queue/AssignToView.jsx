// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import COPY from '../../COPY.json';

import {
  appealWithDetailSelector,
  tasksForAppealAssignedToUserSelector,
  incompleteOrganizationTasksByAssigneeIdSelector,
  rootTasksForAppealIfMailTeamMemberSelector
} from './selectors';

import { setTaskAttrs } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import TextareaField from '../components/TextareaField';

import editModalBase from './components/EditModalBase';
import { requestSave } from './uiReducer/uiActions';

import type { State } from './types/state';
import type { Appeal, Task } from './types/models';

type Params = {|
  appealId: string,
  task: Task,
  createsMailTask: boolean,
  isTeamAssign: boolean
|};

type Props = Params & {|
  appeal: Appeal,
  highlightFormItems: boolean,
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

    if (instructions && instructionLength > 0 && !this.props.isTeamAssign) {
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
      isTeamAssign,
      createsMailTask
    } = this.props;
    const payload = {
      data: {
        tasks: [{
          type: createsMailTask ? 'MailTask' : 'GenericTask',
          external_id: appeal.externalId,
          parent_id: task.taskId,
          assigned_to_id: this.state.selectedValue,
          assigned_to_type: isTeamAssign ? 'Organization' : 'User',
          instructions: this.state.instructions
        }]
      }
    };
    const successMsg = {
      title: `Task assigned to ${this.props.isTeamAssign ? 'team' : 'person'}`
    };

    return this.props.requestSave('/tasks', payload, successMsg).
      then(() => {
        this.props.setTaskAttrs(task.uniqueId, { status: 'on_hold' });
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
      incompleteOrganizationTasksByAssigneeIdSelector(state, { appealId: ownProps.appealId })[0] ||
      rootTasksForAppealIfMailTeamMemberSelector(state, {appealId: ownProps.appealId })[0],
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  setTaskAttrs
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(
  editModalBase(AssignToView, COPY.ASSIGN_TO_PAGE_TITLE)
)): React.ComponentType<Params>);
