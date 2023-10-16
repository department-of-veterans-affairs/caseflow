import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import COPY from '../../COPY';

import { onReceiveAmaTasks } from './QueueActions';
import { requestSave, resetSuccessMessages, highlightInvalidFormItems } from './uiReducer/uiActions';
import { taskActionData } from './utils';
import { taskById, appealWithDetailSelector } from './selectors';

import QueueFlowPage from './components/QueueFlowPage';
import SearchableDropdown from '../components/SearchableDropdown';
import TextareaField from '../components/TextareaField';
import RadioField from '../components/RadioField';
import Modal from '../components/Modal';
import Alert from '../components/Alert';

const ADVANCEMENT_REASONS = [
  'Death dismissal',
  'Withdrawal',
  'Medical',
  'Other'
];

const caseInfoStyling = css({
  '& span': { marginRight: '30px' }
});

const bottomBorderStyling = css({
  borderBottom: '.1rem solid lightgray',
  paddingBottom: '15px',
  marginBottom: '15px'
});

const bottomMarginStyling = css({
  marginBottom: '1.6rem'
});

class BlockedAdvanceToJudgeView extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      cancellationInstructions: '',
      error: null,
      instructions: '',
      selectedAssignee: null,
      selectedReason: null,
      showModal: false
    };
  }

  componentDidMount = () => this.props.resetSuccessMessages();

  validAssignee = () => this.state.selectedAssignee !== null;
  validInstructions = () => this.state.instructions.length > 0;
  validCancellationInstructions = () => this.state.cancellationInstructions.length > 0;
  validReason = () => this.state.selectedReason !== null;

  validatePage = () => this.validCancellationInstructions() && this.validReason();
  validateModal = () => this.validInstructions() && this.validAssignee();

  goToNextStep = () => this.setState({ showModal: true });

  actionData = () => taskActionData(this.props);

  getAssigneeLabel = () => {
    let assignee = 'person';

    this.actionData().options.forEach((opt) => {
      if (opt.value === this.state.selectedAssignee) {
        assignee = opt.label;
      }
    });

    return assignee;
  };

  submit = () => {
    if (!this.validateModal()) {
      this.props.highlightInvalidFormItems(true);

      return;
    }

    const { appeal, task } = this.props;

    const payload = {
      data: {
        tasks: [
          {
            type: this.actionData().type,
            external_id: appeal.externalId,
            parent_id: task.taskId,
            assigned_to_id: this.state.selectedAssignee,
            assigned_to_type: 'User',
            instructions: [
              `${this.state.selectedReason}: ${this.state.cancellationInstructions}`,
              this.state.instructions
            ]
          }
        ]
      }
    };

    const successMessage = {
      title: sprintf(COPY.ASSIGN_TASK_SUCCESS_MESSAGE, this.getAssigneeLabel()),
      detail: this.actionData().message_detail
    };

    return this.props.
      requestSave('/tasks', payload, successMessage).
      then((resp) => {
        this.props.history.replace(`/queue/appeals/${appeal.externalId}`);
        this.props.onReceiveAmaTasks(resp.body.tasks.data);
      }).
      catch((err) => {
        this.setState({
          error: {
            title: sprintf(COPY.BLOCKED_SPECIAL_CASE_MOVEMENT_MODAL_ERROR_TITLE, this.getAssigneeLabel()),
            details: JSON.parse(err?.message)?.errors[0]?.detail
          }
        });
      });
  };

  blockingTaskListItem = (blockingTask) =>
    <li key={blockingTask.id}>{blockingTask.type} - assigned to: {this.blockingTaskAssigneeLink(blockingTask)}</li>;

  blockingTaskAssigneeLink = (blockingTask) => {
    const { appeal } = this.props;

    if (blockingTask.assigned_to_email) {
      const body = `Case Link: ${window.location.origin}/queue/appeals/${appeal.externalId}`,
        emailAddress = blockingTask.assigned_to_email,
        subject = `${blockingTask.type}: ${appeal.veteranFullName}`;

      return <a href={`mailto:${emailAddress}?subject=${subject}&body=${body}`}>{blockingTask.assigned_to_name}</a>;
    }

    return blockingTask.assigned_to_name;
  }

  modalAlert = () => {
    if (!this.state.error) {
      return;
    }

    return <Alert title={this.state.error.title} type="error">{this.state.error.details}</Alert>;
  }

  warningModal = () => {
    if (!this.state.showModal) {
      return;
    }

    const { highlightFormItems } = this.props;

    const options = this.actionData().options;
    const selectedJudgeName = this.getAssigneeLabel() || 'judge';

    return <div className="cf-modal-scroll">
      <Modal
        title={COPY.BLOCKED_SPECIAL_CASE_MOVEMENT_MODAL_TITLE}
        buttons={[{
          classNames: ['usa-button', 'cf-btn-link'],
          name: 'Close',
          onClick: () => this.setState({ showModal: false })
        }, {
          classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
          name: COPY.BLOCKED_SPECIAL_CASE_MOVEMENT_MODAL_SUBMIT,
          onClick: this.submit
        }]}
        closeHandler={() => this.setState({ showModal: false })}
        icon="warning"
      >
        {this.modalAlert()}
        <div {...bottomBorderStyling}>
          <strong>Please Note:</strong> {COPY.BLOCKED_SPECIAL_CASE_MOVEMENT_PAGE_SUBTITLE}<br />
          <strong>Cancellation of task(s) are final.</strong>
        </div>
        <h3>{COPY.BLOCKED_SPECIAL_CASE_MOVEMENT_MODAL_JUDGE_HEADER}</h3>
        <SearchableDropdown
          name="Assign to selector"
          searchable
          hideLabel
          errorMessage={this.props.highlightFormItems && !this.validAssignee() ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          value={this.state.selectedAssignee}
          onChange={(option) => this.setState({ selectedAssignee: option ? option.value : null })}
          options={options}
        />
        <h3>{sprintf(COPY.BLOCKED_SPECIAL_CASE_MOVEMENT_MODAL_INSTRUCTIONS_HEADER, selectedJudgeName)}</h3>
        <TextareaField
          required
          errorMessage={highlightFormItems && !this.validInstructions() ? 'Judge instructions field is required' : null}
          id="judgeInstructions"
          onChange={(value) => this.setState({ instructions: value })}
          value={this.state.instructions}
        />
      </Modal>
    </div>;
  }

  render = () => {
    const { highlightFormItems, appeal } = this.props;

    const blockingTasks = this.actionData().blocking_tasks;

    return <React.Fragment>
      {this.warningModal()}
      <QueueFlowPage
        goToNextStep={this.goToNextStep}
        validateForm={this.validatePage}
        appealId={appeal.externalId}
        hideCancelButton
      >
        <h1>{sprintf(COPY.BLOCKED_SPECIAL_CASE_MOVEMENT_PAGE_TITLE, appeal.veteranFullName)}</h1>
        <div className="cf-sg-subsection" {...caseInfoStyling} {...bottomBorderStyling}>
          <span><strong>Veteran ID: </strong>{appeal.veteranFileNumber}</span>
          <span><strong>Task: </strong>Reassign</span>
        </div>
        <div {...bottomMarginStyling}>{COPY.BLOCKED_SPECIAL_CASE_MOVEMENT_PAGE_SUBTITLE}</div>
        <h3>{COPY.BLOCKED_SPECIAL_CASE_MOVEMENT_PAGE_TASKS_HEADER}</h3>
        <ul>{blockingTasks.map((blockingTask) => this.blockingTaskListItem(blockingTask))}</ul>
        <h3>{COPY.BLOCKED_SPECIAL_CASE_MOVEMENT_PAGE_REASONING_HEADER}</h3>
        <RadioField
          required
          errorMessage={highlightFormItems && !this.validReason() ? 'Reason field is required' : null}
          options={ADVANCEMENT_REASONS.map((reason) => {
            return { displayText: reason, value: reason };
          })}
          id="advancementReason"
          value={this.state.selectedReason}
          onChange={(value) => this.setState({ selectedReason: value })}
          vertical={false}
        />
        <TextareaField
          required
          errorMessage={
            highlightFormItems && !this.validCancellationInstructions() ? 'Instructions field is required' : null
          }
          id="cancellationInstructions"
          onChange={(value) => this.setState({ cancellationInstructions: value })}
          value={this.state.cancellationInstructions}
        />
      </QueueFlowPage>
    </React.Fragment>;
  };
}

BlockedAdvanceToJudgeView.propTypes = {
  appeal: PropTypes.shape({
    externalId: PropTypes.string,
    id: PropTypes.string,
    veteranFullName: PropTypes.string,
    veteranFileNumber: PropTypes.string,
  }),
  highlightInvalidFormItems: PropTypes.func,
  highlightFormItems: PropTypes.bool,
  history: PropTypes.object,
  onReceiveAmaTasks: PropTypes.func,
  requestSave: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  task: PropTypes.shape({
    instructions: PropTypes.string,
    taskId: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => {
  return {
    highlightFormItems: state.ui.highlightFormItems,
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      requestSave,
      onReceiveAmaTasks,
      resetSuccessMessages,
      highlightInvalidFormItems
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(BlockedAdvanceToJudgeView)
);
