import * as React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import RadioField from '../../components/RadioField';
import { ATTORNEY_COMMENTS_MAX_LENGTH, marginTop, slimHeight } from '../constants';
import TextareaField from 'app/components/TextareaField';
import Alert from 'app/components/Alert';
import COPY from '../../../COPY';

import { taskById, appealWithDetailSelector } from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData } from '../utils';

import QueueFlowModal from './QueueFlowModal';

const MarkTaskCompleteModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);
  const instructionsLabel = taskConfiguration && taskConfiguration.instructions_label;

  return (
    <React.Fragment>
      {taskConfiguration && taskConfiguration.modal_body}
      {taskConfiguration && taskConfiguration.modal_alert && (
        <Alert message={taskConfiguration.modal_alert} type="info" />
      )}
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <TextareaField
          label={instructionsLabel || 'Instructions:'}
          name="instructions"
          id="completeTaskInstructions"
          onChange={(value) => setState({ instructions: value })}
          value={state.instructions}
          styling={marginTop(4)}
          maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
        />
      )}
    </React.Fragment>
  );
};

MarkTaskCompleteModal.propTypes = {
  props: PropTypes.object,
  setState: PropTypes.func,
  state: PropTypes.object
};

const locationTypeOpts = [
  { displayText: 'VBMS', value: 'vbms' },
  { displayText: 'Centralized Mail Portal', value: 'centralized mail portal' },
  { displayText: 'Other', value: 'other' }
];

const ReadyForReviewModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);

  const handleRadioChange = (value) => {
    setState({ radio: value });
    if (value === 'other') {
      setState({ otherInstructions: '' });
    }
  };
  const handleTextFieldChange = (value) => {
    setState({ otherInstructions: value });
  };

  return (
    <React.Fragment>
      {taskConfiguration && taskConfiguration.modal_body}
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <div>
          <RadioField
            name="vhaCompleteTaskDocLocation"
            id="vhaCompleteTaskDocLocation"
            label={COPY.VHA_COMPLETE_TASK_MODAL_TITLE}
            inputRef={props.register}
            vertical
            onChange={handleRadioChange}
            value={state.radio}
            options={locationTypeOpts}
          />
          {state.radio === 'other' &&
            <TextareaField
              label='If "Other" was chosen indicate the source.'
              name="otherVhaCompleteTaskDocLocation"
              id="vhaCompleteTaskOtherInstructions"
              onChange={handleTextFieldChange}
              value={state.otherInstructions}
              styling={marginTop(4)}
              textAreaStyling={slimHeight}
            />}
          <TextareaField
            label={COPY.VHA_COMPLETE_TASK_MODAL_BODY}
            name="instructions"
            id="vhaCompleteTaskInstructions"
            onChange={(value) => setState({ instructions: value })}
            value={state.instructions}
            styling={marginTop(4)}
            maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
          />
        </div>
      )}
    </React.Fragment>
  );
};

ReadyForReviewModal.propTypes = {
  props: PropTypes.object,
  setState: PropTypes.func,
  state: PropTypes.object,
  register: PropTypes.func,
};

const SendColocatedTaskModal = ({ appeal, teamName }) => (
  <React.Fragment>
    {sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_COPY, appeal.veteranFullName, appeal.veteranFileNumber)}&nbsp;
    <strong>{teamName}</strong>.
  </React.Fragment>
);

SendColocatedTaskModal.propTypes = {
  appeal: PropTypes.shape({
    veteranFileNumber: PropTypes.string,
    veteranFullName: PropTypes.string
  }),
  teamName: PropTypes.string
};

const MODAL_TYPE_ATTRS = {
  mark_task_complete: {
    buildSuccessMsg: (appeal, { contact }) => ({
      title: sprintf(COPY.MARK_TASK_COMPLETE_CONFIRMATION, appeal.veteranFullName),
      detail: sprintf(COPY.MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, contact)
    }),
    title: () => COPY.MARK_TASK_COMPLETE_TITLE,
    getContent: MarkTaskCompleteModal,
    buttonText: COPY.MARK_TASK_COMPLETE_BUTTON
  },
  ready_for_review: {
    buildSuccessMsg: (appeal, { assignedToType }) => ({
      title: assignedToType === 'VhaProgramOffice' ?
        sprintf(COPY.VHA_COMPLETE_TASK_CONFIRMATION_PO, appeal.veteranFullName) :
        sprintf(COPY.VHA_COMPLETE_TASK_CONFIRMATION_VISN, appeal.veteranFullName)
    }),
    title: () => COPY.VHA_COMPLETE_TASK_LABEL,
    getContent: ReadyForReviewModal,
    buttonText: COPY.MODAL_SUBMIT_BUTTON
  },
  send_colocated_task: {
    buildSuccessMsg: (appeal, { teamName }) => ({
      title: sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_CONFIRMATION, appeal.veteranFullName, teamName)
    }),
    title: ({ teamName }) => sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_HEAD, teamName),
    getContent: SendColocatedTaskModal,
    buttonText: COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_BUTTON
  },
  docket_appeal: {
    buildSuccessMsg: () => ({
      title: sprintf(COPY.DOCKET_APPEAL_CONFIRMATION_TITLE),
      detail: sprintf(COPY.DOCKET_APPEAL_CONFIRMATION_DETAIL)
    }),
    title: () => COPY.DOCKET_APPEAL_MODAL_TITLE,
    getContent: MarkTaskCompleteModal,
    buttonText: COPY.MODAL_CONFIRM_BUTTON
  },
  vha_send_to_board_intake: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.VHA_SEND_TO_BOARD_INTAKE_CONFIRMATION, appeal.veteranFullName)
    }),
    title: () => COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_TITLE,
    getContent: MarkTaskCompleteModal,
    buttonText: COPY.MODAL_SUBMIT_BUTTON
  }
};

class CompleteTaskModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      instructions: '',
      radio: '',
      otherInstructions: ''
    };
  }

  getTaskAssignerName = () => {
    const {
      task: { assignedBy }
    } = this.props;

    // Tasks created by the application (tasks for quality review or dispatch) will not have assigners.
    // TODO: Amend copy to better explain what is going on instead of having a blank field where we expect
    // to see somebody's name.
    if (!assignedBy.firstName.codePointAt(0)) {
      return '';
    }

    return `${assignedBy.firstName} ${assignedBy.lastName}`;
  };

  getTaskConfiguration = () => {
    return taskActionData(this.props) || {};
  };

  getTaskAssignedToType = () => {
    const {
      task: { assignedTo }
    } = this.props;

    return `${assignedTo.type}`;
  };

  getContentArgs = () => ({
    contact: this.getTaskConfiguration().contact || this.getTaskAssignerName(),
    teamName: this.props.task.label,
    appeal: this.props.appeal,
    props: this.props,
    assignedToType: this.getTaskAssignedToType(),
    state: this.state,
    setState: this.setState.bind(this)
  });

  formatInstructions = () => {
    const { instructions, radio, otherInstructions } = this.state;
    let formattedInstructions = instructions;

    if (radio) {
      const locationLabel = locationTypeOpts.find((option) => radio === option.value).displayText;
      const docLocationText = `Documents for this appeal are stored in ${radio === 'other' ? otherInstructions :
        locationLabel}.`;

      formattedInstructions = docLocationText;
      if (instructions) {
        const instructionsDetail = `\n\n**Detail:**\n\n${instructions}`;

        formattedInstructions += instructionsDetail;
      }
    }

    return formattedInstructions;
  };

  submit = () => {
    const { task, appeal } = this.props;
    const detail = 'Detail:';
    // const boldText = detail.replace(new RegExp(`(^|\\s)(${ detail })(\\s|$)`, 'ig'), '$1<b>$2</b>$3');
    const modifiedInstructions =
      `Documents for this appeal are stored in ${this.state.radio === 'other' ? this.state.otherInstructions :
        this.state.radio}\n\n**${detail}** ${this.state.instructions}`;
    const payload = {
      data: {
        task: {
          status: 'completed',
          instructions: this.formatInstructions()
        }
      }
    };
    const successMsg = MODAL_TYPE_ATTRS[this.props.modalType].buildSuccessMsg(
      appeal,
      this.getContentArgs()
    );

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).then((resp) => {
      this.props.onReceiveAmaTasks(resp.body.tasks.data);
    });
  };

  render = () => {
    const modalAttributes = MODAL_TYPE_ATTRS[this.props.modalType];

    return (
      <QueueFlowModal
        title={modalAttributes.title(this.getContentArgs())}
        button={modalAttributes.buttonText}
        submit={this.submit}
        pathAfterSubmit={this.getTaskConfiguration().redirect_after || '/queue'}
      >
        {this.props.task ?
          modalAttributes.getContent(this.getContentArgs()) :
          null}
      </QueueFlowModal>
    );
  };
}

CompleteTaskModal.propTypes = {
  appeal: PropTypes.shape({
    veteranFileNumber: PropTypes.string,
    veteranFullName: PropTypes.string
  }),
  modalType: PropTypes.string,
  onReceiveAmaTasks: PropTypes.func,
  requestPatch: PropTypes.func,
  task: PropTypes.shape({
    assignedBy: PropTypes.shape({
      firstName: PropTypes.string,
      lastName: PropTypes.string
    }),
    assignedTo: PropTypes.shape({
      type: PropTypes.string
    }),
    label: PropTypes.string,
    taskId: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      requestPatch,
      onReceiveAmaTasks
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CompleteTaskModal)
);
