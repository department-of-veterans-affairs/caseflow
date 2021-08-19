import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import COPY from '../../COPY';

import { taskById, appealWithDetailSelector } from './selectors';

import { onReceiveAmaTasks, legacyReassignToJudge, setOvertime } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import TextareaField from '../components/TextareaField';
import QueueFlowModal from './components/QueueFlowModal';

import { requestPatch, requestSave, resetSuccessMessages } from './uiReducer/uiActions';

import { taskActionData } from './utils';

const selectedAction = (props) => {
  const actionData = taskActionData(props);

  return actionData.selected ? actionData.options.find((option) => option.value === actionData.selected.id) : null;
};

const getAction = (props) => {
  return props.task && props.task.availableActions.length > 0 ? selectedAction(props) : null;
};

class AssignToView extends React.Component {
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

  componentDidMount = () => this.props.resetSuccessMessages();

  validateForm = () => {
    return this.state.selectedValue !== null && this.state.instructions !== '';
  };

  submit = () => {
    const { appeal, task, isReassignAction, isTeamAssign } = this.props;

    const action = getAction(this.props);
    const isPulacCerullo = action && action.label === 'Pulac-Cerullo';

    const actionData = taskActionData(this.props);
    const taskType = actionData.type || 'Task';

    const payload = {
      data: {
        tasks: [
          {
            type: taskType,
            external_id: appeal.externalId,
            parent_id: actionData.parent_id || task.taskId,
            assigned_to_id: this.state.selectedValue,
            assigned_to_type: isTeamAssign ? 'Organization' : 'User',
            instructions: this.state.instructions
          }
        ]
      }
    };

    const assignTaskSuccessMessage = {
      title: sprintf(COPY.ASSIGN_TASK_SUCCESS_MESSAGE, this.getAssignee()),
      detail: taskActionData(this.props).message_detail
    };

    const pulacCerulloSuccessMessage = {
      title: COPY.PULAC_CERULLO_SUCCESS_TITLE,
      detail: sprintf(COPY.PULAC_CERULLO_SUCCESS_DETAIL, appeal.veteranFullName)
    };

    if (isReassignAction) {
      return this.reassignTask(taskType === 'JudgeLegacyAssignTask');
    }

    return this.props.
      requestSave('/tasks', payload, isPulacCerullo ? pulacCerulloSuccessMessage : assignTaskSuccessMessage).
      then((resp) => this.props.onReceiveAmaTasks(resp.body.tasks.data)).
      catch(() => {
        // handle the error from the frontend
      });
  };

  getAssignee = () => {
    let assignee = 'person';

    taskActionData(this.props).options.forEach((opt) => {
      if (opt.value === this.state.selectedValue) {
        assignee = opt.label;
      }
    });

    return assignee;
  };

  reassignTask = (isLegacyReassignToJudge = false) => {
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

    const successMsg = { title: sprintf(COPY.REASSIGN_TASK_SUCCESS_MESSAGE, this.getAssignee()) };

    if (isLegacyReassignToJudge) {
      return this.props.legacyReassignToJudge({
        tasks: [task],
        assigneeId: this.state.selectedValue
      }, successMsg);
    }

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).then((resp) => {
      this.props.onReceiveAmaTasks(resp.body.tasks.data);
      if (task.type === 'JudgeAssignTask') {
        this.props.setOvertime(task.externalAppealId, false);
      }
    });
  };

  determineTitle = (props, action, isPulacCerullo, actionData) => {
    if (actionData.modal_title) {
      return actionData.modal_title;
    }
    if (props.assigneeAlreadySelected && action) {
      if (isPulacCerullo) {
        return COPY.PULAC_CERULLO_MODAL_TITLE;
      }

      return sprintf(COPY.ASSIGN_TASK_TO_TITLE, action.label);
    }

    return COPY.ASSIGN_TASK_TITLE;
  };

  determinePlaceholder = (props, actionData) => {
    if (actionData.modal_selector_placeholder) {
      return actionData.modal_selector_placeholder;
    }

    if (this.props.isTeamAssign) {
      return COPY.ASSIGN_TO_TEAM_DROPDOWN;
    }

    return COPY.ASSIGN_TO_USER_DROPDOWN;
  };

  render = () => {
    const { assigneeAlreadySelected, highlightFormItems, task } = this.props;

    const action = getAction(this.props);
    const actionData = taskActionData(this.props);
    const isPulacCerullo = action && action.label === 'Pulac-Cerullo';

    if (!task || task.availableActions.length === 0) {
      return null;
    }

    const modalProps = {
      title: this.determineTitle(this.props, action, isPulacCerullo, actionData),
      pathAfterSubmit: (actionData && actionData.redirect_after) || '/queue',
      submit: this.submit,
      submitDisabled: !this.validateForm(),
      validateForm: isPulacCerullo ?
        () => {
          return true;
        } :
        this.validateForm
    };

    if (isPulacCerullo) {
      modalProps.button = 'Notify';
    }

    return (
      <QueueFlowModal {...modalProps}>
        <p>{actionData.modal_body ? actionData.modal_body : ''}</p>
        {!assigneeAlreadySelected && (
          <React.Fragment>
            <SearchableDropdown
              name="Assign to selector"
              searchable
              hideLabel
              errorMessage={highlightFormItems && !this.state.selectedValue ? 'Choose one' : null}
              placeholder={this.determinePlaceholder(this.props, actionData)}
              value={this.state.selectedValue}
              onChange={(option) => this.setState({ selectedValue: option ? option.value : null })}
              options={taskActionData(this.props).options}
            />
            <br />
          </React.Fragment>
        )}
        {!isPulacCerullo && (
          <TextareaField
            name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
            errorMessage={highlightFormItems && !this.state.instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
            id="taskInstructions"
            onChange={(value) => this.setState({ instructions: value })}
            value={this.state.instructions}
          />
        )}
        {isPulacCerullo && (
          <div>
            <p>{COPY.PULAC_CERULLO_MODAL_BODY_1}</p>
            <p>{COPY.PULAC_CERULLO_MODAL_BODY_2}</p>
          </div>
        )}
      </QueueFlowModal>
    );
  };
}

AssignToView.propTypes = {
  appeal: PropTypes.shape({
    externalId: PropTypes.string,
    id: PropTypes.string,
    veteranFullName: PropTypes.string
  }),
  assigneeAlreadySelected: PropTypes.bool,
  highlightFormItems: PropTypes.bool,
  isReassignAction: PropTypes.bool,
  isTeamAssign: PropTypes.bool,
  onReceiveAmaTasks: PropTypes.func,
  legacyReassignToJudge: PropTypes.func,
  requestPatch: PropTypes.func,
  requestSave: PropTypes.func,
  task: PropTypes.shape({
    instructions: PropTypes.string,
    taskId: PropTypes.string,
    availableActions: PropTypes.arrayOf(PropTypes.object),
    externalAppealId: PropTypes.string,
    type: PropTypes.string
  }),
  setOvertime: PropTypes.func,
  resetSuccessMessages: PropTypes.func
};

const mapStateToProps = (state, ownProps) => {
  const { highlightFormItems } = state.ui;

  return {
    highlightFormItems,
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      requestPatch,
      requestSave,
      onReceiveAmaTasks,
      legacyReassignToJudge,
      setOvertime,
      resetSuccessMessages
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(AssignToView)
);
