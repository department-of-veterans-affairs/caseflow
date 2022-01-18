import * as React from 'react';
import ReactMarkdown from 'react-markdown';
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

import { taskById, appealWithDetailSelector, getAllTasksForAppeal } from '../selectors';
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

const sendToBoardOpts = [
  { displayText: COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_CORRECT_DOCUMENTS, value: 'correct documents' },
  { displayText: COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_NOT_APPEALABLE, value: 'not appealable' },
  { displayText: COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_NO_VHA_DECISION, value: 'no vha decision' },
  { displayText: COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_NOT_VHA_RELATED, value: 'not vha related' }
];

const SendToBoardIntakeModal = ({ props, state, setState }) => {

  const taskConfiguration = taskActionData(props);

  // if the VhaProgramOffice has completed a task, show the task instructions in the modal
  const programOfficeInstructions = props.tasks.map((task) => {
    return task && task.assignedTo.type === 'VhaProgramOffice' && task.instructions[1];
  });

  return (
    <React.Fragment>
      {programOfficeInstructions && <strong style= {{ color: '#323a45' }}>Notes from Program Office:</strong>}
      {programOfficeInstructions.map((text) => (
        <React.Fragment>
          <div>
            <ReactMarkdown>{text}</ReactMarkdown>
          </div>
        </React.Fragment>
      ))}
      {taskConfiguration && taskConfiguration.modal_body}
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <div>
          <hr style= {{ marginBottom: '1.5em' }} />
          <RadioField
            name="sendToBoardIntakeOptions"
            id="sendToBoardIntakeOptions"
            label={COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_DETAIL}
            inputRef={props.register}
            vertical
            onChange={(value) => setState({ radio: value })}
            value={state.radio}
            options={sendToBoardOpts}
          />
          <div style= {{ color: ' #cc0000' }}>{state.errors.sendToBoardIntakeOptions}</div>
          <TextareaField
            label={COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_BODY}
            name="instructions"
            id="vhaSendToBoardIntakeInstructions"
            onChange={(value) => setState({ instructions: value })}
            value={state.instructions}
            styling={marginTop(4)}
            maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
          />
          <div style= {{ color: ' #cc0000' }}>{state.errors.instructions}</div>
        </div>
      )}
    </React.Fragment>
  );
};

SendToBoardIntakeModal.propTypes = {
  props: PropTypes.object,
  tasks: PropTypes.array,
  setState: PropTypes.func,
  state: PropTypes.object,
  register: PropTypes.func
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
    getContent: SendToBoardIntakeModal,
    buttonText: COPY.MODAL_SUBMIT_BUTTON
  }
};

class CompleteTaskModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      instructions: '',
      radio: '',
      otherInstructions: '',
      errors: {}
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
    let reviewNotes;

    const previousInstructions = this.props.tasks.map((task) => {
      if (task.assignedTo.type === 'VhaProgramOffice') {
        reviewNotes = 'Program Office';

        return task && task.instructions[1];
      } else if (task.assignedTo.type === 'VhaRegionalOffice') {
        reviewNotes = 'VISN';

        return task && task.instructions[1];
      } else if (task.assignedTo.type === 'VhaCamo') {
        reviewNotes = 'CAMO';

        return task && task.instructions[1];
      }

      return reviewNotes = null;
    });

    if (this.props.modalType === 'vha_send_to_board_intake') {
      const locationLabel = sendToBoardOpts.find((option) => radio === option.value).displayText;

      if (reviewNotes) {
        formattedInstructions = `\n\n**Status:** ${locationLabel}\n\n
        \n\n**${reviewNotes} Notes:** ${previousInstructions.join('')}`;
      }

      if (instructions) {
        const instructionsDetail = `\n\n**CAMO Notes:** ${instructions}`;

        formattedInstructions += instructionsDetail;
      }
    } else if (this.props.modalType === 'ready_for_review') {
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

  validateForm = () => {
    const { instructions, radio } = this.state;
    const errors = {};

    if (radio === '') {
      errors.sendToBoardIntakeOptions = '*Please select an option.';
    }

    if (instructions === '') {
      errors.instructions = '*Textfield cannot be blank.';
    }

    this.setState({
      errors
    });

    if (radio === '' || instructions === '') {
      return false;
    }

    this.submit();

  }

  submit = () => {
    const { task, appeal } = this.props;

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
        submit={this.validateForm()}
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
  tasks: getAllTasksForAppeal(state, ownProps),
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
