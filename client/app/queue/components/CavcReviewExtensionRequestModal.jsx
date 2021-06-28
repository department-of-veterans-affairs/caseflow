import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import { startCase } from 'lodash';
import { sprintf } from 'sprintf-js';

import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import TextField from '../../components/TextField';

import ApiUtil from '../../util/ApiUtil';
import { showSuccessMessage } from '../uiReducer/uiActions';

import { COLOCATED_HOLD_DURATIONS, CUSTOM_HOLD_DURATION_TEXT } from '../constants';
import COPY from '../../../COPY';
import Alert from '../../components/Alert';

const decisions = [
  COPY.CAVC_EXTENSION_REQUEST_GRANT,
  COPY.CAVC_EXTENSION_REQUEST_DENY
];
const helpText = {
  [COPY.CAVC_EXTENSION_REQUEST_GRANT]: COPY.CAVC_EXTENSION_REQUEST_GRANT_HELP_TEXT,
  [COPY.CAVC_EXTENSION_REQUEST_DENY]: COPY.CAVC_EXTENSION_REQUEST_DENY_HELP_TEXT
};
const decisionOptions = decisions.map((value) => (
  {
    value,
    displayText: startCase(value),
    help: helpText[value]
  }
));

/**
 * Modal to allow a user to grant or deny a cavc remand extension request. All fields are required.
 */
export const CavcReviewExtensionRequestModalUnconnected = ({ onCancel, onSubmit, error }) => {
  const [decision, setDecision] = useState();
  const [holdDuration, setHoldDuration] = useState();
  const [customHoldDuration, setCustomHoldDuration] = useState();
  const [instructions, setInstructions] = useState();
  const [highlightFormItems, setHighlightFormItems] = useState(false);

  const granted = () => decision === decisions[0];
  const usingCustomHold = () => holdDuration?.value === CUSTOM_HOLD_DURATION_TEXT;

  const validDecision = () => Boolean(decision);
  // Don't need to validate on hold duration if going deny route
  const validHoldDuration = () => !granted() || Boolean(holdDuration?.value);
  // Don't need to validate custom on hold duration if going deny route or if using a pre-selected hold value
  const validCustomHoldDuration = () => !granted() || !usingCustomHold() || customHoldDuration > 0;
  const validInstructions = () => Boolean(instructions);
  const validateForm = () => validDecision() && validHoldDuration() && validCustomHoldDuration() && validInstructions();

  const cancel = () => onCancel();
  const submit = () => {
    if (validateForm()) {
      const selectedHoldDuration = usingCustomHold() ? customHoldDuration : holdDuration?.value;

      onSubmit(decision, instructions, granted() ? selectedHoldDuration : null);
    } else {
      setHighlightFormItems(true);
    }
  };

  const modalButtons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: cancel,
    },
    {
      classNames: ['usa-button', 'usa-button-secondary'],
      name: 'Confirm',
      onClick: submit,
    },
  ];

  const decisionField = <RadioField
    name="decision"
    label={COPY.CAVC_EXTENSION_REQUEST_DECISION_LABEL}
    errorMessage={highlightFormItems && !validDecision() ? 'Choose one' : null}
    value={decision}
    onChange={setDecision}
    options={decisionOptions}
    strongLabel
  />;

  const holdDurationField = () => (
    granted() ? <SearchableDropdown
      name="duration"
      label={COPY.COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL}
      placeholder={COPY.COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL}
      errorMessage={highlightFormItems && !validHoldDuration() ? 'Choose one' : null}
      value={holdDuration}
      onChange={setHoldDuration}
      options={COLOCATED_HOLD_DURATIONS.map((value) => ({
        label: Number(value) ? `${value} days` : value,
        value
      }))}
    /> : null
  );

  const customHoldField = () => (
    granted() && usingCustomHold() ? <TextField
      name="customDuration"
      label={COPY.COLOCATED_ACTION_PLACE_CUSTOM_HOLD_COPY}
      type="number"
      value={customHoldDuration}
      onChange={setCustomHoldDuration}
      errorMessage={highlightFormItems && !validCustomHoldDuration() ?
        COPY.COLOCATED_ACTION_PLACE_CUSTOM_HOLD_INVALID_VALUE : null
      }
      inputProps={{ min: 1 }}
    /> : null
  );

  const instructionsField = <TextareaField
    name="instructions"
    label={COPY.CAVC_INSTRUCTIONS_LABEL}
    errorMessage={highlightFormItems && !validInstructions() ? COPY.CAVC_INSTRUCTIONS_ERROR : null}
    value={instructions}
    onChange={setInstructions}
  />;

  const errorAlert = () => error?.title ? <Alert title={error.title} message={error?.detail} type="error" /> : null;

  return (
    <Modal
      title={COPY.CAVC_EXTENSION_REQUEST_TITLE}
      buttons={modalButtons}
      closeHandler={onCancel}
    >
      { errorAlert() }
      { decisionField }
      { holdDurationField() }
      { customHoldField() }
      { instructionsField }
    </Modal>
  );
};

CavcReviewExtensionRequestModalUnconnected.propTypes = {

  /**
   * Callback for when the user presses the confirm button and the form is valid. Will be passed the following params
   *
   * @param {string} decision     The decision the user has made, one of "grant" or "deny"
   * @param {string} instructions The instructions provided with the decision
   * @param {number} holdDuration The number of days to grant an extension for. Will be null if the extension request is
   *                              denied
   */
  onSubmit: PropTypes.func,

  /**
   * Callback for when the user presses the cancel button
   */
  onCancel: PropTypes.func,

  /**
   * Any errors to display in the modal. Automatically set if the request was not successful
   */
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  })
};

const CavcReviewExtensionRequestModal = ({ closeModal, taskId }) => {
  const dispatch = useDispatch();
  const [error, setError] = useState();

  const onCancel = () => closeModal();
  const onSubmit = (decision, instructions, holdDuration) => {
    const payload = {
      data: {
        task: {
          days_on_hold: holdDuration,
          instructions: [instructions],
          decision
        }
      }
    };

    ApiUtil.post(`/tasks/${taskId}/extension_request/`, payload).then(() => {
      const successMessage = decision === 'grant' ?
        {
          title: sprintf(COPY.CAVC_EXTENSION_REQUEST_GRANT_SUCCESS_TITLE, holdDuration),
          detail: COPY.CAVC_EXTENSION_REQUEST_GRANT_SUCCESS_DETAIL
        } : {
          title: COPY.CAVC_EXTENSION_REQUEST_DENY_SUCCESS_TITLE,
          detail: COPY.CAVC_EXTENSION_REQUEST_DENY_SUCCESS_DETAIL
        };

      dispatch(showSuccessMessage(successMessage));
      closeModal();
    }, (err) => {
      setError(err.response.body.errors[0]);
    });
  };

  return <CavcReviewExtensionRequestModalUnconnected
    onCancel={onCancel}
    onSubmit={onSubmit}
    error={error}
  />;
};

CavcReviewExtensionRequestModal.propTypes = {

  /**
   * Callback to close the modal and return to the previous page
   */
  closeModal: PropTypes.func,

  /**
   * The id of the CavcRemandProcessedLetterResponseWindowTask the extension request is for
   */
  taskId: PropTypes.string
};

export default CavcReviewExtensionRequestModal;
