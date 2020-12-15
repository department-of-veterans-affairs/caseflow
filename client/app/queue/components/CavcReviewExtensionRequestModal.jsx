import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';

import { COLOCATED_HOLD_DURATIONS } from '../constants';
import COPY from '../../../COPY';

export const CavcReviewExtensionRequestModal = (props) => {
  const [decision, setDecision] = useState();
  const [holdDuration, setHoldDuration] = useState();
  const [instructions, setInstructions] = useState();
  const [highlightFormItems, setHighlightFormItems] = useState(false);

  const validDecision = () => Boolean(decision);
  const validHoldDuration = () => decision === 'Deny' || Boolean(holdDuration?.value);
  const validInstructions = () => Boolean(instructions);
  const validateForm = () => validDecision() && validHoldDuration() && validInstructions();

  const onSubmit = () => {
    if (!validateForm()) {
      setHighlightFormItems(true);

      return;
    }

    props.onSubmit(decision, instructions, holdDuration?.value);
  };

  const radioOptions = [
    {
      value: 'Grant',
      displayText: 'Grant',
      help: 'Task will be go on hold for selected number of days'
    },
    {
      value: 'Deny',
      displayText: 'Deny',
      help: 'Task will be marked completed and sent to case distribution'
    }
  ];

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: props.onCancel,
    },
    {
      classNames: ['usa-button', 'usa-button-secondary'],
      name: 'Confirm',
      onClick: onSubmit,
    },
  ];

  return (
    <Modal
      title="Review extension request"
      buttons={buttons}
      {...props}
    >
      <RadioField
        options={radioOptions}
        label="How will you proceed?"
        name="grant-or-deny"
        value={decision}
        onChange={setDecision}
        errorMessage={highlightFormItems && !validDecision() ? 'Choose one' : null}
        strongLabel
      />
      { decision === 'Grant' && <SearchableDropdown
        name={COPY.COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL}
        searchable={false}
        errorMessage={highlightFormItems && !validHoldDuration() ? 'Choose one' : null}
        placeholder={COPY.COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL}
        value={holdDuration}
        onChange={setHoldDuration}
        options={COLOCATED_HOLD_DURATIONS.map((value) => ({
          label: Number(value) ? `${value} days` : value,
          value
        }))} /> }
      <TextareaField
        label={COPY.CAVC_INSTRUCTIONS_LABEL}
        name="extensionInstructions"
        value={instructions}
        onChange={setInstructions}
        errorMessage={highlightFormItems && !validInstructions() ? 'Please enter context for this action' : null}
      />
    </Modal>
  );
};

CavcReviewExtensionRequestModal.propTypes = {
  onSubmit: PropTypes.func,
  onCancel: PropTypes.func
};

export default CavcReviewExtensionRequestModal;
