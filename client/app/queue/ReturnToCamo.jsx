import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import COPY from '../../COPY';

import { taskById, appealWithDetailSelector } from './selectors';

import { onReceiveAmaTasks, legacyReassignToJudge, setOvertime } from './QueueActions';

import TextareaField from '../components/TextareaField';
import QueueFlowModal from './components/QueueFlowModal';

import { requestGet, requestSave, showSuccessMessage, resetSuccessMessages } from './uiReducer/uiActions';

import { taskActionData } from './utils';
import ApiUtil from '../util/ApiUtil';

const selectedAction = (props) => {
  const actionData = taskActionData(props);

  return actionData.selected ? actionData.options.find((option) => option.value === actionData.selected.id) : null;
};

const getAction = (props) => {
  return props.task && props.task.availableActions.length > 0 ? selectedAction(props) : null;
};

class ReturnToCamo extends React.Component {
  constructor(props) {
    super(props);

    // Autofill the instruction field if assigning to a person on the team. Since they will
    // probably want the instructions from the assigner.
    const instructions = this.props.task.instructions;
    const instructionLength = instructions ? instructions.length : 0;
    let existingInstructions = '';

    if (instructions && instructionLength > 0) {
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
    return this.state.instructions !== '';
  };

  submit = () => {
    const { appeal, task } = this.props;

    const action = getAction(this.props);

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
            assigned_to_type: 'Organization',
            instructions: this.state.instructions
          }
        ]
      }
    };

    return this.reassignTask();
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

  reassignTask = () => {
    const task = this.props.task;
    const payload = {
      data: {
        task: {
          reassign: {
            assigned_to_id: this.state.selectedValue,
            assigned_to_type: 'Organization',
            instructions: this.state.instructions
          }
        }
      }
    };

    const successMsg = { title: sprintf(COPY.RETURN_TASK_SUCCESS_MESSAGE) };

    this.props.showSuccessMessage(successMsg);
    this.props.history.goBack();
  };

  render = () => {
    const { assigneeAlreadySelected, highlightFormItems, task } = this.props;

    const actionData = taskActionData(this.props);

    if (!task || task.availableActions.length === 0) {
      return null;
    }

    const modalProps = {
      title: 'Return to Program Office',
      pathAfterSubmit: '/queue',
      submit: this.submit,
      validateForm:
        this.validateForm
    };


    return (
      <QueueFlowModal {...modalProps}>
        <TextareaField
          name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
          errorMessage={highlightFormItems && !this.state.instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          id="taskInstructions"
          onChange={(value) => this.setState({ instructions: value })}
          value={this.state.instructions}
        />
      </QueueFlowModal>
    );
  };
}

ReturnToCamo.propTypes = {
  appeal: PropTypes.shape({
    externalId: PropTypes.string,
    id: PropTypes.string,
    veteranFullName: PropTypes.string
  }),
  assigneeAlreadySelected: PropTypes.bool,
  highlightFormItems: PropTypes.bool,
  onReceiveAmaTasks: PropTypes.func,
  legacyReassignToJudge: PropTypes.func,
  requestGet: PropTypes.func,
  requestSave: PropTypes.func,
  task: PropTypes.shape({
    instructions: PropTypes.string,
    taskId: PropTypes.string,
    availableActions: PropTypes.arrayOf(PropTypes.object),
    externalAppealId: PropTypes.string,
    type: PropTypes.string
  }),
  setOvertime: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  showSuccessMessage: PropTypes.func
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
      requestGet,
      requestSave,
      onReceiveAmaTasks,
      legacyReassignToJudge,
      setOvertime,
      resetSuccessMessages,
      showSuccessMessage
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(ReturnToCamo)
);
