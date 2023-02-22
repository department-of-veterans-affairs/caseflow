/* eslint-disable max-lines */
import * as React from 'react';
import ReactMarkdown from 'react-markdown';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import RadioField from '../../components/RadioField';
import { ATTORNEY_COMMENTS_MAX_LENGTH, marginTop, setHeight, slimHeight } from '../constants';
import TextareaField from 'app/components/TextareaField';
import SearchableDropdown from '../../components/SearchableDropdown';
import Alert from 'app/components/Alert';
import COPY from '../../../COPY';
import { taskById, appealWithDetailSelector, getAllTasksForAppeal } from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData } from '../utils';
import StringUtil from '../../util/StringUtil';
import QueueFlowModal from './QueueFlowModal';

const validRadio = (radio) => {
  return radio?.length > 0;
};

const validInstructions = (instructions) => {
  return instructions?.length > 0;
};

const validDropdown = (dropdown) => {
  return dropdown?.length > 0;
};

const handleDropdownStateChange = (value, setState) => {
  setState({ dropdown: value });
  if (value === 'other') {
    setState({ otherInstructions: '' });
  }
};

const formatOtherInstructions = (state) => {
  let formattedInstructions = '';

  if (state.dropdown === 'other') {
    formattedInstructions += `\n**Reason for return:**\nOther - ${state.otherInstructions}`;
  } else {
    formattedInstructions += `\n**Reason for return:**\n${state.dropdown}`;
  }

  if (state.instructions) {
    formattedInstructions += `\n\n**Detail:**\n${state.instructions}`;
  }

  return formattedInstructions;
};

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
          optional
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

  const getTaskType = () => {
    return taskConfiguration?.type || null;
  };
  const isOptional = () => {
    // eslint-disable-next-line camelcase
    return taskConfiguration?.body_optional || false;
  };
  const handleRadioChange = (value) => {
    setState({ radio: value });
    if (value === 'other') {
      setState({ otherInstructions: '' });
    }
  };
  const handleTextFieldChange = (value) => {
    setState({ otherInstructions: value });
  };
  const modalLabel = () => {
    if (getTaskType() === 'AssessDocumentationTask') {
      return COPY.VHA_COMPLETE_TASK_MODAL_TITLE;
    } else if ((getTaskType() === 'VhaDocumentSearchTask') || (getTaskType()?.includes('Education'))) {
      return StringUtil.nl2br(COPY.DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_BODY);
    }

    return null;
  };

  return (
    <React.Fragment>
      {taskConfiguration && taskConfiguration.modal_body}
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <div>
          <RadioField
            name="completeTaskDocLocation"
            id="completeTaskDocLocation"
            label={modalLabel()}
            inputRef={props.register}
            vertical
            onChange={handleRadioChange}
            value={state.radio}
            options={locationTypeOpts}
            errorMessage={props.highlightInvalid && !validRadio(state.radio) ? COPY.SELECT_RADIO_ERROR : null}
          />
          {state.radio === 'other' &&
            <TextareaField
              label="Please indicate the source"
              name="otherCompleteTaskDocLocation"
              id="completeTaskOtherInstructions"
              onChange={handleTextFieldChange}
              value={state.otherInstructions}
              styling={marginTop(4)}
              textAreaStyling={slimHeight}
              errorMessage={props.highlightInvalid &&
                !validInstructions(state.otherInstructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
            />}
          <TextareaField
            label={COPY.VHA_COMPLETE_TASK_MODAL_BODY}
            name="instructions"
            id="completeTaskInstructions"
            onChange={(value) => setState({ instructions: value })}
            maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
            value={state.instructions}
            styling={marginTop(4)}
            errorMessage={props.highlightInvalid &&
              !validInstructions(state.instructions) &&
              !isOptional() ? COPY.EMPTY_INSTRUCTIONS_ERROR :
              null}
            optional={isOptional()}
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
  highlightInvalid: PropTypes.bool
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

  let filteredSendToBoardOpts = sendToBoardOpts;

  if (!props.featureToggles.vha_irregular_appeals) {
    filteredSendToBoardOpts = sendToBoardOpts.filter((opt) => {
      return opt.displayText === COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_CORRECT_DOCUMENTS;
    });
  }

  return (
    <React.Fragment>
      {programOfficeInstructions.some((i) => i) &&
        <strong style= {{ color: '#323a45' }}>Notes from Program Office:</strong>}
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
            options={filteredSendToBoardOpts}
            errorMessage={props.highlightInvalid && !validRadio(state.radio) ? COPY.SELECT_RADIO_ERROR : null}
          />
          <TextareaField
            label={COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_BODY}
            name="instructions"
            id="vhaSendToBoardIntakeInstructions"
            onChange={(value) => setState({ instructions: value })}
            value={state.instructions}
            styling={marginTop(4)}
            maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
            errorMessage={props.highlightInvalid &&
              !validInstructions(state.instructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
          />
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
  register: PropTypes.func,
  featureToggles: PropTypes.array,
  highlightInvalid: PropTypes.bool
};

const VhaCamoReturnToBoardIntakeModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);
  const dropdownOptions = taskConfiguration.options;

  const handleDropdownChange = ({ value }) => {
    handleDropdownStateChange(value, setState);
  };

  return (
    <React.Fragment>
      {taskConfiguration && taskConfiguration.modal_body}
      <div style= {{ marginBottom: '1.5em' }}>{COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_BODY}</div>
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <div>
          <SearchableDropdown
            name="returnToBoardOptions"
            id="returnToBoardOptions"
            label={COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_DETAIL}
            defaultText={COPY.TASK_ACTION_DROPDOWN_BOX_LABEL_SHORT}
            onChange={handleDropdownChange}
            value={state.dropdown}
            options={dropdownOptions}
            errorMessage={props.highlightInvalid &&
              !validDropdown(state.dropdown) ? 'You must select a reason for returning to intake' : null}
          />
          {state.dropdown === 'other' &&
            <TextareaField
              label={COPY.VHA_RETURN_TO_BOARD_INTAKE_OTHER_INSTRUCTIONS_LABEL}
              name="otherRejectReason"
              id="completeTaskOtherInstructions"
              onChange={(value) => setState({ otherInstructions: value })}
              value={state.otherInstructions}
              styling={marginTop(2)}
              textAreaStyling={setHeight(4.5)}
              errorMessage={props.highlightInvalid &&
                !validInstructions(state.otherInstructions) ? 'Return reason field is required' : null}
            />}
          <TextareaField
            label={COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_INSTRUCTIONS_LABEL}
            name="instructions"
            id="vhaReturnToBoardIntakeInstructions"
            onChange={(value) => setState({ instructions: value })}
            value={state.instructions}
            styling={marginTop(4)}
            maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
            errorMessage={props.highlightInvalid &&
              !validInstructions(state.instructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
          />
        </div>
      )}
    </React.Fragment>
  );
};

VhaCamoReturnToBoardIntakeModal.propTypes = {
  props: PropTypes.object,
  tasks: PropTypes.array,
  setState: PropTypes.func,
  state: PropTypes.object,
  register: PropTypes.func,
  featureToggles: PropTypes.array,
  highlightInvalid: PropTypes.bool
};

const ReturnToBoardIntakeModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);

  return (
    <React.Fragment>
      {taskConfiguration && taskConfiguration.modal_body}
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <div>
          <TextareaField
            label={COPY.EMO_RETURN_TO_BOARD_INTAKE_MODAL_BODY}
            name="instructions"
            id="emoReturnToBoardIntakeInstructions"
            onChange={(value) => setState({ instructions: value })}
            value={state.instructions}
            maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
            errorMessage={props.highlightInvalid &&
              !validInstructions(state.instructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
          />
        </div>
      )}
    </React.Fragment>
  );
};

ReturnToBoardIntakeModal.propTypes = {
  props: PropTypes.object,
  tasks: PropTypes.array,
  setState: PropTypes.func,
  state: PropTypes.object,
  register: PropTypes.func,
  featureToggles: PropTypes.array,
  highlightInvalid: PropTypes.bool
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

const VhaCaregiverSupportReturnToBoardIntakeModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);

  const dropdownOptions = taskConfiguration.options;

  const handleDropdownChange = ({ value }) => {
    handleDropdownStateChange(value, setState);
  };

  return (
    <React.Fragment>
      {taskConfiguration && taskConfiguration.modal_body}
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <div style= {{ marginTop: '1.5rem' }}>
          <SearchableDropdown
            label={COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_DROPDOWN_LABEL}
            defaultText={COPY.TASK_ACTION_DROPDOWN_BOX_LABEL_SHORT}
            name="rejectReason"
            id="caregiverSupportReturnToBoardIntakeReasonSelection"
            options={dropdownOptions}
            onChange={handleDropdownChange}
            value={state.dropdown}
            errorMessage={props.highlightInvalid &&
              !validDropdown(state.dropdown) ? 'You must select a reason for returning to intake' : null}
          />
          {state.dropdown === 'other' &&
            <TextareaField
              label={COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_OTHER_REASON_TEXT_FIELD_LABEL}
              name="otherRejectReason"
              id="completeTaskOtherInstructions"
              onChange={(value) => setState({ otherInstructions: value })}
              value={state.otherInstructions}
              styling={marginTop(2)}
              textAreaStyling={setHeight(4.5)}
              errorMessage={props.highlightInvalid &&
                !validInstructions(state.otherInstructions) ? 'Return reason field is required' : null}
            />}
          <TextareaField
            label={COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_TEXT_FIELD_LABEL}
            name="instructions"
            id="caregiverSupportReturnToBoardIntakeInstructions"
            onChange={(value) => setState({ instructions: value })}
            value={state.instructions}
            styling={marginTop(2)}
            maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
            optional
          />
        </div>
      )}
    </React.Fragment>
  );
};

VhaCaregiverSupportReturnToBoardIntakeModal.propTypes = {
  props: PropTypes.object,
  setState: PropTypes.func,
  state: PropTypes.object,
  highlightInvalid: PropTypes.bool,
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
    title: () => COPY.DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
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
  vha_return_to_board_intake: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.VHA_RETURN_TO_BOARD_INTAKE_CONFIRMATION, appeal.veteranFullName)
    }),
    title: () => COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_TITLE,
    getContent: VhaCamoReturnToBoardIntakeModal,
    buttonText: COPY.MODAL_RETURN_BUTTON,
    submitDisabled: ({ state }) => (
      !validDropdown(state.dropdown) || (state.dropdown === 'other' && !validInstructions(state.otherInstructions))
    ),
    customFormatInstructions: ({ state }) => {
      return formatOtherInstructions(state);
    }
  },
  vha_send_to_board_intake: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.VHA_SEND_TO_BOARD_INTAKE_CONFIRMATION, appeal.veteranFullName)
    }),
    title: () => COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_TITLE,
    getContent: SendToBoardIntakeModal,
    buttonText: COPY.MODAL_SUBMIT_BUTTON
  },
  emo_return_to_board_intake: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.EMO_RETURN_TO_BOARD_INTAKE_CONFIRMATION, appeal.veteranFullName)
    }),
    title: () => COPY.EMO_RETURN_TO_BOARD_INTAKE_MODAL_TITLE,
    getContent: ReturnToBoardIntakeModal,
    buttonText: COPY.MODAL_RETURN_BUTTON
  },
  emo_send_to_board_intake_for_review: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.EDU_SEND_TO_BOARD_INTAKE_FOR_REVIEW_CONFIRMATION_PO, appeal.veteranFullName)
    }),
    title: () => COPY.DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
    getContent: ReadyForReviewModal,
    buttonText: COPY.MODAL_SUBMIT_BUTTON
  },
  rpo_send_to_board_intake_for_review: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.EDU_SEND_TO_BOARD_INTAKE_FOR_REVIEW_CONFIRMATION_PO, appeal.veteranFullName)
    }),
    title: () => COPY.DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
    getContent: ReadyForReviewModal,
    buttonText: COPY.MODAL_SUBMIT_BUTTON
  },
  vha_caregiver_support_return_to_board_intake: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_SUCCESS_CONFIRMATION, appeal.veteranFullName)
    }),
    title: () => COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_TITLE,
    getContent: VhaCaregiverSupportReturnToBoardIntakeModal,
    buttonText: COPY.MODAL_RETURN_BUTTON,
    submitButtonClassNames: ['usa-button'],
    submitDisabled: ({ state }) => (
      !validDropdown(state.dropdown) || (state.dropdown === 'other' && !validInstructions(state.otherInstructions))
    ),
    customValidation: ({ state }) => (
      state.dropdown === 'other' ? validInstructions(state.otherInstructions) && validDropdown(state.dropdown) :
        validDropdown(state.dropdown)
    ),
    customFormatInstructions: ({ state }) => {
      return formatOtherInstructions(state);
    }
  },

  vha_caregiver_support_send_to_board_intake_for_review: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(
        COPY.VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_CONFIRMATION_TITLE, appeal.veteranFullName)
    }),
    title: () => COPY.DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
    getContent: ReadyForReviewModal,
    buttonText: COPY.MODAL_SEND_BUTTON,
    submitDisabled: ({ state }) => {
      const { otherInstructions, radio } = state;

      let isValid = true;

      if (radio === 'other') {
        isValid = validInstructions(otherInstructions) && validRadio(radio);
      } else {
        isValid = validRadio(radio);
      }

      return !isValid;
    }
  },
};

class CompleteTaskModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      instructions: '',
      radio: '',
      dropdown: '',
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
    const formattedInstructions = [];
    let reviewNotes;
    const previousInstructions = this.props.tasks.map((task) => {
      // Skip if there are no previous instructions
      if (task.instructions?.[1]) {
        if (task.assignedTo.type === 'VhaProgramOffice') {
          reviewNotes = 'Program Office';

          return task && task.instructions[1];
        } else if (task.assignedTo.type === 'VhaRegionalOffice') {
          reviewNotes = 'VISN';

          return task && task.instructions[1];
        } else if (task.assignedTo.type === 'VhaCamo' && task.instructions.length > 0) {
          reviewNotes = 'CAMO';

          return task && task.instructions[1];
        }
      }

      return reviewNotes = null;
    });

    if (this.props.modalType === 'vha_send_to_board_intake') {
      const locationLabel = sendToBoardOpts.find((option) => radio === option.value).displayText;

      formattedInstructions.push(`\n**Status:** ${locationLabel}\n`);

      if (reviewNotes) {
        formattedInstructions.push(`\n\n**${reviewNotes} Notes:** ${previousInstructions.join('')}\n`);
      }

      if (instructions) {
        const instructionsDetail = `\n**CAMO Notes:** ${instructions}`;

        formattedInstructions.splice(1, 0, instructionsDetail);
      }
    } else if (this.props.modalType.includes('for_review')) {
      const locationLabel = locationTypeOpts.find((option) => radio === option.value).displayText;
      const docLocationText = `Documents for this appeal are stored in ${radio === 'other' ? otherInstructions :
        locationLabel}.`;

      formattedInstructions.push(docLocationText);
      if (instructions) {
        const instructionsDetail = `\n\n**Detail:**\n\n${instructions}\n`;

        formattedInstructions.push(instructionsDetail);
      }
    } else if (typeof MODAL_TYPE_ATTRS[this.props.modalType].customFormatInstructions === 'function') {
      formattedInstructions.push(
        MODAL_TYPE_ATTRS[this.props.modalType].customFormatInstructions(this.getContentArgs())
      );
    } else {
      formattedInstructions.push(instructions);
    }

    return formattedInstructions.join('');
  };

   validateForm = () => {
     const { instructions, otherInstructions, radio } = this.state;
     const modalType = this.props.modalType;

     let isValid = true;

     if (modalType === 'vha_send_to_board_intake' || modalType === 'ready_for_review') {
       isValid = validInstructions(instructions) && validRadio(radio);
     }

     if (modalType === 'emo_return_to_board_intake') {
       isValid = validInstructions(instructions);
     }

     if (modalType === 'emo_send_to_board_intake_for_review' || modalType === 'rpo_send_to_board_intake_for_review') {
       if (radio === 'other') {
         isValid = validInstructions(otherInstructions) && validRadio(radio);
       } else {
         isValid = validRadio(radio);
       }
     }

     // Checks validity using the customValidation function defined in the modal constants if it is present
     if (typeof MODAL_TYPE_ATTRS[this.props.modalType].customValidation === 'function') {
       isValid = MODAL_TYPE_ATTRS[this.props.modalType].customValidation(this.getContentArgs());
     }

     return isValid;
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
        submitDisabled={modalAttributes.submitDisabled?.(this.getContentArgs())}
        validateForm={this.validateForm}
        submit={this.submit}
        pathAfterSubmit={this.getTaskConfiguration().redirect_after || '/queue'}
        submitButtonClassNames={modalAttributes.submitButtonClassNames || ['usa-button']}
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
  tasks: PropTypes.array,
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
  }),
  featureToggles: PropTypes.object,
  highlightInvalid: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  tasks: getAllTasksForAppeal(state, ownProps),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
  featureToggles: state.ui.featureToggles,
  highlightInvalid: state.ui.highlightFormItems
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
