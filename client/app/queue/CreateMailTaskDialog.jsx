import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import COPY from '../../COPY';
import { onReceiveAmaTasks } from './QueueActions';
import SearchableDropdown from '../components/SearchableDropdown';
import TextareaField from '../components/TextareaField';
import { requestSave } from './uiReducer/uiActions';
import { taskById, appealWithDetailSelector } from './selectors';
import QueueFlowModal from './components/QueueFlowModal';

const successAlertContentMap = {
  DocketSwitchMailTask: ({ label }) => ({
    title: sprintf(COPY.SELF_ASSIGNED_MAIL_TASK_CREATION_SUCCESS_TITLE, label),
    detail: COPY.SELF_ASSIGNED_MAIL_TASK_CREATION_SUCCESS_MESSAGE,
  }),
  default: ({ label }) => ({
    title: sprintf(COPY.MAIL_TASK_CREATION_SUCCESS_MESSAGE, label),
  }),
};

const getSuccessAlertContent = (newTask) =>
  successAlertContentMap[newTask.value]?.(newTask) ??
  successAlertContentMap.default(newTask);

export class CreateMailTaskDialog extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      selectedValue: null,
      instructions: '',
    };
  }

  validateForm = () =>
    this.state.selectedValue !== null && this.state.instructions !== '';

  submit = () => {
    const { appeal, task } = this.props;

    const payload = {
      data: {
        tasks: [
          {
            type: this.state.selectedValue,
            external_id: appeal.externalId,
            parent_id: task.taskId,
            instructions: this.state.instructions,
          },
        ],
      },
    };

    const newTask = this.taskActionData().options.find(
      (option) => option.value === this.state.selectedValue
    );

    return this.props.
      requestSave('/tasks', payload, getSuccessAlertContent(newTask)).
      then((resp) => this.props.onReceiveAmaTasks(resp.body.tasks.data)).
      catch(() => {
        // handle the error from the frontend
      });
  };

  taskActionData = () => {
    const relevantAction = this.props.task.availableActions.find((action) =>
      this.props.history.location.pathname.endsWith(action.value)
    );

    if (relevantAction && relevantAction.data) {
      return relevantAction.data;
    }

    // We should never get here since any task action the creates this modal should provide data.
    throw new Error('Task action requires data');
  };

  render = () => {
    const { highlightFormItems, task } = this.props;

    if (!task || task.availableActions.length === 0) {
      return null;
    }

    return (
      <QueueFlowModal
        submit={this.submit}
        validateForm={this.validateForm}
        title={COPY.CREATE_MAIL_TASK_TITLE}
        pathAfterSubmit={`/queue/appeals/${this.props.appealId}`}
      >
        <SearchableDropdown
          name="Correspondence type selector"
          searchable
          hideLabel
          errorMessage={
            highlightFormItems && !this.state.selectedValue ?
              'Choose one' :
              null
          }
          placeholder={COPY.MAIL_TASK_DROPDOWN_TYPE_SELECTOR_LABEL}
          value={this.state.selectedValue}
          onChange={(option) =>
            this.setState({ selectedValue: option ? option.value : null })
          }
          options={this.taskActionData().options}
        />
        <br />
        <TextareaField
          name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
          errorMessage={
            highlightFormItems && !this.state.instructions ?
              COPY.FORM_ERROR_FIELD_REQUIRED :
              null
          }
          id="taskInstructions"
          onChange={(value) => this.setState({ instructions: value })}
          value={this.state.instructions}
        />
      </QueueFlowModal>
    );
  };
}

CreateMailTaskDialog.propTypes = {
  appeal: PropTypes.shape({
    externalId: PropTypes.string,
  }),
  appealId: PropTypes.string,
  highlightFormItems: PropTypes.bool,
  history: PropTypes.shape({
    location: PropTypes.shape({
      pathname: PropTypes.string,
    }),
  }),
  onReceiveAmaTasks: PropTypes.func,
  requestSave: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string,
    availableActions: PropTypes.array,
  }),
};

const mapStateToProps = (state, ownProps) => {
  const { highlightFormItems } = state.ui;

  return {
    highlightFormItems,
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps),
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      requestSave,
      onReceiveAmaTasks,
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CreateMailTaskDialog)
);
