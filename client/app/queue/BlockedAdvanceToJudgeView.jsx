import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import COPY from '../../COPY';

import { taskById, appealWithDetailSelector } from './selectors';

import { onReceiveAmaTasks } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import TextareaField from '../components/TextareaField';
import QueueFlowPage from './components/QueueFlowPage';

import { requestSave, resetSuccessMessages } from './uiReducer/uiActions';

import { taskActionData } from './utils';

class BlockedAdvanceToJudgeView extends React.Component {
  constructor(props) {
    super(props);

    const actionData = taskActionData(props);
    const action = actionData.selected ? actionData.options.find((option) => option.value === actionData.selected.id) : null;

    this.state = {
      selectedValue: action ? action.value : null,
      instructions: []
    };
  }

  componentDidMount = () => this.props.resetSuccessMessages();

  validateForm = () => {
    return this.state.selectedValue !== null && this.state.instructions !== '';
  };

  submit = () => {
    const { appeal, task } = this.props;

    const payload = {
      data: {
        tasks: [
          {
            type: taskType,
            external_id: appeal.externalId,
            parent_id: task.taskId,
            assigned_to_id: this.state.selectedValue,
            assigned_to_type: 'User',
            instructions: this.state.instructions
          }
        ]
      }
    };

    const successMessage = {
      title: sprintf(COPY.ASSIGN_TASK_SUCCESS_MESSAGE, this.getAssignee()),
      detail: taskActionData(this.props).message_detail
    };

    return this.props.
      requestSave('/tasks', payload, successMessage).
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

  render = () => {
    const { highlightFormItems } = this.props;

    const pageProps = {
      title: COPY.TEAM_MANAGEMENT_ADD_JUDGE_TEAM_MODAL_TITLE,
      pathAfterSubmit: '/team_management',
      submit: this.submit,
      validateForm: this.validateForm
    };

    return (
      <QueueFlowPage {...pageProps}>
        <SearchableDropdown
          name="Assign to selector"
          searchable
          hideLabel
          errorMessage={(highlightFormItems && !this.state.selectedValue) ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          placeholder={COPY.TEAM_MANAGEMENT_ADD_JUDGE_TEAM_MODAL_TITLE}
          value={this.state.selectedValue}
          onChange={(option) => this.setState({ selectedValue: option ? option.value : null })}
          options={taskActionData(this.props).options}
        />
        <br />
        <TextareaField
          name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
          errorMessage={(highlightFormItems && !this.state.instructions) ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          id="taskInstructions"
          onChange={(value) => this.setState({ instructions: value })}
          value={this.state.instructions}
        />
      </QueueFlowPage>
    );
  };
}

BlockedAdvanceToJudgeView.propTypes = {
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
      requestSave,
      onReceiveAmaTasks,
      resetSuccessMessages
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(BlockedAdvanceToJudgeView)
);
