/* eslint-disable max-lines */
import * as React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import RadioField from '../../components/RadioField';
import { ATTORNEY_COMMENTS_MAX_LENGTH, marginTop, setHeight } from '../constants';
import TextareaField from 'app/components/TextareaField';
import Alert from 'app/components/Alert';
import COPY from '../../../COPY';
import { taskById, appealWithDetailSelector, getAllTasksForAppeal } from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import { requestPatch } from '../uiReducer/uiActions';
import {
  currentDaysOnHold,
  getPreviousTaskInstructions,
  taskActionData,
} from '../utils';
import StringUtil from '../../util/StringUtil';
import QueueFlowModal from './QueueFlowModal';
import { VhaReturnToBoardIntakeModal } from './VhaReturnToBoardIntakeModal';

const validRadio = (radio) => {
  return radio?.length > 0;
};

const validInstructions = (instructions) => {
  return instructions?.length > 0;
};

const validInstructionsForNumber = (instructions) => {
  return (instructions > 45) && (instructions <= 364);
};

const validDropdown = (dropdown) => {
  return dropdown?.length > 0;
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

const submitDisabled = ({ state }) => {
  const { otherInstructions, radio } = state;

  return !(radio === 'other' ? validRadio(otherInstructions) : validRadio(radio));
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
          optional
        />
      )}
    </React.Fragment>
  );
};

const daysTypeOpts = [
  { displayText: COPY.DAYS_CONTESTED_CLAIM, value: '45' },
  { displayText: COPY.CUSTOM_CONTESTED_CLAIM, value: 'custom' }
];

const finalCompleteTaskRadio = [
  { displayText: 'Yes', value: '1' },
  { displayText: 'No', value: '0' }
];

MarkTaskCompleteModal.propTypes = {
  props: PropTypes.object,
  setState: PropTypes.func,
  state: PropTypes.object
};

const MarkTaskCompleteContestedClaimModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);
  const instructionsLabel = taskConfiguration && taskConfiguration.instructions_label;
  const currentType = props.task.type;

  if (currentType === 'SendInitialNotificationLetterTask') {
    return (
      <React.Fragment>
        <div className="cc_mark_complete">
          {taskConfiguration && StringUtil.nl2br(taskConfiguration.modal_body)}
          {taskConfiguration && taskConfiguration.modal_alert && (
            <Alert message={taskConfiguration.modal_alert} type="info" />
          )}
          {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
            <div>
              <RadioField
                id="45_days"
                inputRef={props.register}
                vertical
                onChange={(value) => setState({ radio: value })}
                value={state.radio}
                options={daysTypeOpts}
                errorMessage={props.highlightInvalid && !validRadio(state.radio) ? COPY.SELECT_RADIO_ERROR : null}
                styling={marginTop(1)}
              />
              {state.radio === 'custom' &&
                <TextareaField
                  label={instructionsLabel || COPY.TEXTAREA_CONTESTED_CLAIM}
                  name="instructions"
                  id="completeTaskInstructions"
                  onChange={(value) => setState({ instructions: value })}
                  value={state.value}
                  styling={marginTop(1.0)}
                  textAreaStyling={setHeight(4.5)}
                  pattern="[0-9]{2,3}"
                  maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
                />}
            </div>
          )}
        </div>
      </React.Fragment>
    );
  }

  return (
    <React.Fragment>
      <div className="cc_mark_complete">
        {taskConfiguration && StringUtil.nl2br(taskConfiguration.modal_body)}
        {taskConfiguration && taskConfiguration.modal_alert && (
          <Alert message={taskConfiguration.modal_alert} type="info" />
        )}
        {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
          <div>
            <RadioField
              id="complete_task_final"
              inputRef={props.register}
              vertical
              onChange={(value) => setState({ radio: value })}
              value={state.radio}
              options={finalCompleteTaskRadio}
              errorMessage={props.highlightInvalid && !validRadio(state.radio) ? COPY.SELECT_RADIO_ERROR : null}
              styling={marginTop(1)}
            />
            {state.radio === '1' &&
              <TextareaField
                label="Provide instructions and context for this action"
                name="instructions"
                id="completeTaskInstructions"
                onChange={(value) => setState({ instructions: value })}
                value={state.instructions}
                styling={marginTop(1)}
                maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
                placeholder="This is a description of instructions and context for this action."
                errorMessage={props.highlightInvalid &&
                  !validInstructions(state.instructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
              />}
          </div>
        )}
      </div>
    </React.Fragment>
  );
};

const ProceedFinalNotificationLetterTaskModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);

  return (
    <React.Fragment>
      {taskConfiguration && taskConfiguration.modal_body}
      {taskConfiguration && taskConfiguration.modal_alert && (
        <Alert message={taskConfiguration.modal_alert} type="info" />
      )}
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <TextareaField
          label="Provide instructions and context for this action"
          name="instructions"
          id="completeTaskInstructions"
          onChange={(value) => setState({ instructions: value })}
          value={state.instructions}
          styling={marginTop(4)}
          maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
          placeholder="This is a description of instuctions and context for this action."
          errorMessage={props.highlightInvalid &&
            !validInstructions(state.instructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
        />
      )}
    </React.Fragment>
  );
};

const ResendFinalNotificationLetterTaskModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);

  return (
    <React.Fragment>
      {taskConfiguration && taskConfiguration.modal_body}
      {taskConfiguration && taskConfiguration.modal_alert && (
        <Alert message={taskConfiguration.modal_alert} type="info" />
      )}
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <TextareaField
          label="Provide instructions and context for this action"
          name="instructions"
          id="completeTaskInstructions"
          onChange={(value) => setState({ instructions: value })}
          value={state.instructions}
          styling={marginTop(4)}
          maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
          placeholder="This is a description of instuctions and context for this action."
          errorMessage={props.highlightInvalid &&
            !validInstructions(state.instructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
        />
      )}
    </React.Fragment>
  );
};

const ResendInitialNotificationLetterTaskModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);

  return (
    <React.Fragment>
      {taskConfiguration && taskConfiguration.modal_body}
      {taskConfiguration && taskConfiguration.modal_alert && (
        <Alert message={taskConfiguration.modal_alert} type="info" />
      )}
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <TextareaField
          label="Provide instructions and context for this action"
          name="instructions"
          id="completeTaskInstructions"
          onChange={(value) => setState({ instructions: value })}
          value={state.instructions}
          styling={marginTop(4)}
          maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
          placeholder="This is a description of instuctions and context for this action."
          errorMessage={props.highlightInvalid &&
            !validInstructions(state.instructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
        />
      )}
    </React.Fragment>
  );
};

ResendInitialNotificationLetterTaskModal.propTypes = {
  props: PropTypes.object,
  setState: PropTypes.func,
  highlightInvalid: PropTypes.bool,
  state: PropTypes.object
};
MarkTaskCompleteContestedClaimModal.propTypes = {
  props: PropTypes.object,
  setState: PropTypes.func,
  state: PropTypes.object,
  register: PropTypes.func,
  highlightInvalid: PropTypes.bool,
  task: PropTypes.object
};

ProceedFinalNotificationLetterTaskModal.propTypes = {
  props: PropTypes.object,
  setState: PropTypes.func,
  state: PropTypes.object,
  highlightInvalid: PropTypes.bool
};

ResendFinalNotificationLetterTaskModal.propTypes = {
  props: PropTypes.object,
  setState: PropTypes.func,
  highlightInvalid: PropTypes.bool,
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
      return StringUtil.nl2br(taskConfiguration.radio_field_label);
    } else if ((getTaskType() === 'VhaDocumentSearchTask') || (getTaskType()?.includes('Education'))) {
      return StringUtil.nl2br(COPY.DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_BODY);
    }

    return null;
  };

  return (
    <React.Fragment>
      {taskConfiguration && StringUtil.nl2br(taskConfiguration.modal_body)}
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <div style={{ marginTop: '1.25rem' }}>
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
              styling={marginTop(1.0)}
              textAreaStyling={setHeight(4.5)}
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
            styling={marginTop(1.5)}
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

const VhaCamoReturnToBoardIntakeModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);

  return (
    <React.Fragment>
      <VhaReturnToBoardIntakeModal
        modalBody={COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_BODY}
        dropdownLabel={COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_DETAIL}
        dropdownDefaultText={COPY.TASK_ACTION_DROPDOWN_BOX_LABEL_SHORT}
        otherLabel={COPY.VHA_RETURN_TO_BOARD_INTAKE_OTHER_INSTRUCTIONS_LABEL}
        instructionsLabel={COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_INSTRUCTIONS_LABEL}
        highlightInvalid={props.highlightInvalid}
        taskConfiguration={taskConfiguration}
        state={state}
        setState={setState}
        instructionsOptional
      />
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
            label={taskConfiguration.instructions_label || COPY.PRE_DOCKET_INSTRUCTIONS_LABEL}
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

  return (
    <React.Fragment>
      <VhaReturnToBoardIntakeModal
        modalBody={COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_BODY}
        dropdownLabel={COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_DROPDOWN_LABEL}
        dropdownDefaultText={COPY.TASK_ACTION_DROPDOWN_BOX_LABEL_SHORT}
        otherLabel={COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_OTHER_REASON_TEXT_FIELD_LABEL}
        highlightInvalid={props.highlightInvalid}
        instructionsLabel={COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_TEXT_FIELD_LABEL}
        taskConfiguration={taskConfiguration}
        state={state}
        setState={setState}
        instructionsOptional
      />
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
    getContent: MarkTaskCompleteModal
  },

  task_complete_contested_claim: {
    buildSuccessMsg: (appeal, { contact }) => ({
      title: sprintf(COPY.MARK_TASK_COMPLETE_CONFIRMATION, appeal.veteranFullName),
      detail: sprintf(COPY.MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, contact)
    }),
    title: () => COPY.MARK_TASK_COMPLETE_TITLE_CONTESTED_CLAIM,
    getContent: MarkTaskCompleteContestedClaimModal,
    buttonText: COPY.MARK_TASK_COMPLETE_BUTTON_CONTESTED_CLAIM,
    submitButtonClassNames: ['usa-button'],

    submitDisabled: ({ state }) => {
      const { instructions, radio } = state;

      let isValid = true;

      if (radio === 'custom') {
        isValid = validInstructionsForNumber(instructions) && validRadio(radio);
      } else if (radio === '45') {
        isValid = validRadio(radio);
      } else if (radio === '1') {
        isValid = validInstructions(instructions) && validRadio(radio);
      } else if (radio === '') {
        isValid = validRadio(radio);
      }

      return !isValid;
    }
  },

  proceed_final_notification_letter_initial: {
    buildSuccessMsg: () => ({
      title: sprintf(COPY.PROCEED_FINAL_NOTIFICATION_LETTER_INITIAL_TASK_SUCCESS),
    }),
    title: () => COPY.PROCEED_FINAL_NOTIFICATION_LETTER_TITLE,
    getContent: ProceedFinalNotificationLetterTaskModal,
    buttonText: COPY.PROCEED_FINAL_NOTIFICATION_LETTER_BUTTON,
    submitButtonClassNames: ['usa-button'],
    submitDisabled: ({ state }) => (!validInstructions(state.instructions))
  },

  proceed_final_notification_letter_post_holding: {
    buildSuccessMsg: () => ({
      title: sprintf(COPY.PROCEED_FINAL_NOTIFICATION_LETTER_POST_HOLDING_TASK_SUCCESS),
    }),
    title: () => COPY.PROCEED_FINAL_NOTIFICATION_LETTER_TITLE,
    getContent: ProceedFinalNotificationLetterTaskModal,
    buttonText: COPY.PROCEED_FINAL_NOTIFICATION_LETTER_BUTTON,
    submitButtonClassNames: ['usa-button'],
    submitDisabled: ({ state }) => (!validInstructions(state.instructions))
  },

  resend_initial_notification_letter_post_holding: {
    buildSuccessMsg: () => ({
      title: sprintf(COPY.RESEND_INITIAL_NOTIFICATION_LETTER_POST_HOLDING_TASK_SUCCESS),
    }),
    title: () => COPY.RESEND_INITIAL_NOTIFICATION_LETTER_TITLE,
    getContent: ResendInitialNotificationLetterTaskModal,
    buttonText: COPY.RESEND_INITIAL_NOTIFICATION_LETTER_BUTTON,
    submitButtonClassNames: ['usa-button'],
    submitDisabled: ({ state }) => (!validInstructions(state.instructions))
  },

  resend_initial_notification_letter_final: {
    buildSuccessMsg: () => ({
      title: sprintf(COPY.RESEND_INITIAL_NOTIFICATION_LETTER_FINAL_TASK_SUCCESS),
    }),
    title: () => COPY.RESEND_INITIAL_NOTIFICATION_LETTER_TITLE,
    getContent: ResendInitialNotificationLetterTaskModal,
    buttonText: COPY.RESEND_INITIAL_NOTIFICATION_LETTER_BUTTON,
    submitButtonClassNames: ['usa-button'],
    submitDisabled: ({ state }) => (!validInstructions(state.instructions))
  },

  resend_final_notification_letter: {
    buildSuccessMsg: () => ({
      title: sprintf(COPY.RESEND_FINAL_NOTIFICATION_LETTER_TASK_SUCCESS),
    }),
    title: () => COPY.RESEND_FINAL_NOTIFICATION_LETTER_TITLE,
    getContent: ResendFinalNotificationLetterTaskModal,
    buttonText: COPY.RESEND_FINAL_NOTIFICATION_LETTER_BUTTON,
    submitButtonClassNames: ['usa-button'],
    submitDisabled: ({ state }) => (!validInstructions(state.instructions))
  },

  ready_for_review: {
    buildSuccessMsg: (appeal, { assignedToType }) => ({
      title: assignedToType === 'VhaProgramOffice' ?
        sprintf(COPY.VHA_COMPLETE_TASK_CONFIRMATION_PO, appeal.veteranFullName) :
        sprintf(COPY.VHA_COMPLETE_TASK_CONFIRMATION_VISN, appeal.veteranFullName)
    }),
    getContent: ReadyForReviewModal
  },
  send_colocated_task: {
    buildSuccessMsg: (appeal, { teamName }) => ({
      title: sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_CONFIRMATION, appeal.veteranFullName, teamName)
    }),
    title: ({ teamName }) => sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_HEAD, teamName),
    getContent: SendColocatedTaskModal
  },
  docket_appeal: {
    buildSuccessMsg: () => ({
      title: sprintf(COPY.DOCKET_APPEAL_CONFIRMATION_TITLE),
      detail: sprintf(COPY.DOCKET_APPEAL_CONFIRMATION_DETAIL)
    }),
    title: () => COPY.DOCKET_APPEAL_MODAL_TITLE,
    getContent: MarkTaskCompleteModal
  },
  vha_documents_ready_for_bva_intake_for_review: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(
        COPY.VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_CONFIRMATION_TITLE,
        appeal.veteranFullName
      )
    }),
    title: () => COPY.DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
    getContent: ReadyForReviewModal,
    buttonText: COPY.MODAL_SEND_BUTTON,
    submitDisabled
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
  emo_return_to_board_intake: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.EMO_RETURN_TO_BOARD_INTAKE_CONFIRMATION, appeal.veteranFullName)
    }),
    title: () => COPY.EMO_RETURN_TO_BOARD_INTAKE_MODAL_TITLE,
    getContent: ReturnToBoardIntakeModal,
    customFormatInstructions: ({ state }) => {
      if (state.instructions.length > 0) {
        return `\n##### REASON FOR RETURN:\n${state.instructions}`;
      }

      return state.instructions;
    }
  },
  emo_send_to_board_intake_for_review: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.EDU_SEND_TO_BOARD_INTAKE_FOR_REVIEW_CONFIRMATION_PO, appeal.veteranFullName)
    }),
    title: () => COPY.DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
    getContent: ReadyForReviewModal
  },
  rpo_send_to_board_intake_for_review: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.EDU_SEND_TO_BOARD_INTAKE_FOR_REVIEW_CONFIRMATION_PO, appeal.veteranFullName)
    }),
    title: () => COPY.DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
    getContent: ReadyForReviewModal
  },
  vha_caregiver_support_return_to_board_intake: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_SUCCESS_CONFIRMATION, appeal.veteranFullName)
    }),
    title: () => COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_TITLE,
    getContent: VhaCaregiverSupportReturnToBoardIntakeModal,
    customValidation: ({ state }) => (
      state.dropdown === 'other' ? validInstructions(state.otherInstructions) && validDropdown(state.dropdown) :
        validDropdown(state.dropdown)
    ),
    customFormatInstructions: ({ state }) => {
      let formattedInstructions = '';

      if (state.dropdown === 'other') {
        formattedInstructions += `\n##### REASON FOR RETURN:\nOther - ${state.otherInstructions}`;
      } else {
        formattedInstructions += `\n##### REASON FOR RETURN:\n${state.dropdown}`;
      }

      if (state.instructions) {
        formattedInstructions += `\n\n##### DETAILS:\n${state.instructions}`;
      }

      return formattedInstructions;
    }
  },
  vha_caregiver_support_send_to_board_intake_for_review: {
    buildSuccessMsg: (appeal) => ({
      title: sprintf(
        COPY.VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_CONFIRMATION_TITLE, appeal.veteranFullName)
    }),
    title: () => COPY.DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
    getContent: ReadyForReviewModal,
    submitDisabled
  }
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

  formatRadio = () => {
    const { instructions, radio } = this.state;

    if (this.props.modalType === 'task_complete_contested_claim' &&
      this.props.task.type === 'SendInitialNotificationLetterTask') {
      const radioValue = daysTypeOpts.find((option) => radio === option.value).value;

      if (radioValue === 'custom') {
        return instructions;
      }

      return radioValue;
    }

    if (this.props.modalType === 'task_complete_contested_claim' &&
      this.props.task.type === 'SendFinalNotificationLetterTask') {
      const radioValue = finalCompleteTaskRadio.find((option) => radio === option.value).value;

      return radioValue;
    }
  }

  formatInstructions = () => {
    const { instructions, radio, otherInstructions } = this.state;
    const formattedInstructions = [];
    const {
      previousInstructions,
      reviewNotes
    } = getPreviousTaskInstructions(this.props.task, this.props.tasks);

    if (this.props.modalType === 'task_complete_contested_claim' &&
      this.props.task.type === 'SendInitialNotificationLetterTask') {
      const radioValue = daysTypeOpts.find((option) => radio === option.value).value;
      let days;

      if (radioValue === 'custom') {
        days = instructions;
      } else {
        days = radioValue;
      }

      formattedInstructions.push(`\n Hold time: ${days} days\n\n`);

      return formattedInstructions[0];
    }

    if (this.props.task.type === 'SendFinalNotificationLetterTask' &&
      this.props.modalType === 'task_complete_contested_claim') {
      const radioValue = finalCompleteTaskRadio.find((option) => radio === option.value).value;

      if (radioValue === '0' || radioValue === '1') {
        return formattedInstructions.join('');
      }
    }

    if (this.props.task.type !== 'SendInitialNotificationLetterTask') {
      if ((this.props.modalType === 'proceed_final_notification_letter_post_holding') ||
        (this.props.modalType === 'resend_initial_notification_letter')) {
        const currentTaskID = this.props.task.taskId;

        this.props.tasks.forEach((data) => {
          if (data.taskId === currentTaskID) {
            const onHolddays = currentDaysOnHold(data);
            const totalDays = data.onHoldDuration;

            return formattedInstructions.push(`\n Hold time: ${onHolddays} / ${totalDays} days\n\n`);
          }
        });
      }
    }

    if (this.props.modalType.includes('for_review')) {
      const locationLabel = locationTypeOpts.find((option) => radio === option.value).displayText;

      const docLocationText = `##### STATUS:\nDocuments for this appeal are stored in ${radio === 'other' ?
        otherInstructions :
        locationLabel}.`;

      formattedInstructions.push(docLocationText);

      if (instructions) {
        formattedInstructions.push(`\n\n##### DETAILS:\n${instructions}\n`);
      }

      // Do not add "Regional Processing Office Notes" section when RPO is sending to Intake for review
      if (reviewNotes && reviewNotes !== 'Regional Processing Office') {
        formattedInstructions.push(`\n### ${reviewNotes} Notes:\n${previousInstructions}\n`);
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

    if (modalType.includes('send_to_board_intake_for_review') ||
      modalType === 'vha_documents_ready_for_bva_intake_for_review'
    ) {
      if (radio === 'other') {
        isValid = validInstructions(otherInstructions) && validRadio(radio);
      } else {
        isValid = validRadio(radio);
      }

      return isValid;
    }

    if (modalType.includes('for_review')) {
      if (radio === 'other') {
        isValid = validInstructions(otherInstructions) && validRadio(radio) && validInstructions(instructions);
      } else {
        if (modalType === 'vha_documents_ready_for_bva_intake_for_review' ||
          modalType === 'vha_return_to_board_intake'
        ) {
          isValid = validRadio(radio);
        }

        isValid = validRadio(radio) && validInstructions(instructions);
      }
    }

    if (modalType === 'emo_return_to_board_intake') {
      isValid = validInstructions(instructions);
    }

    // Checks validity using the customValidation function defined in the modal constants if it is present
    if (typeof MODAL_TYPE_ATTRS[this.props.modalType].customValidation === 'function') {
      isValid = MODAL_TYPE_ATTRS[this.props.modalType].customValidation(this.getContentArgs());
    }

    return isValid;
  }

  submit = () => {
    const { task, appeal } = this.props;
    const statusValue = ((task.type === 'SendFinalNotificationLetterTask') &&
      (MODAL_TYPE_ATTRS[this.props.modalType].title() === 'Resend initial notification letter') ?
      'cancelled' : 'completed');
    const payload = {
      data: {
        task: {
          status: statusValue,
          instructions: this.formatInstructions(),
        },
        select_opc: this.props.modalType,
        radio_value: this.formatRadio(),
        instructions: this.state.instructions,
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
    const taskData = taskActionData(this.props);
    const path = (
      (MODAL_TYPE_ATTRS[this.props.modalType].buttonText === 'Proceed to final letter') ||
      (MODAL_TYPE_ATTRS[this.props.modalType].buttonText === 'Resend notification letter') ||
      (this.props.modalType === 'task_complete_contested_claim')
    ) ? ('/organizations/clerk-of-the-board?tab=unassignedTab&page=1') : (
        taskData.redirect_after || '/queue'
      );

    return (
      <QueueFlowModal
        title={taskData.modal_title || (modalAttributes.title && modalAttributes.title(this.getContentArgs()))}
        /* eslint-disable-next-line camelcase */
        button={taskData?.modal_button_text}
        submitDisabled={!this.validateForm()}
        validateForm={this.validateForm}
        submit={this.submit}
        pathAfterSubmit={path}
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
    taskId: PropTypes.string,
    type: PropTypes.string
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
