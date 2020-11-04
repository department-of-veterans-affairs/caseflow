import React, { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import Modal from '../../components/Modal';
import SearchableDropdown from '../../components/SearchableDropdown';
import {
  EDIT_CLAIM_LABEL_MODAL_TITLE,
  EDIT_CLAIM_LABEL_MODAL_SUBHEAD,
  EDIT_CLAIM_LABEL_MODAL_NOTE,
} from '../../../COPY';

export const EditClaimLabelModal = ({ existingLabel, onCancel, onSubmit }) => {
  const [newLabel, setNewLabel] = useState(existingLabel);
  const handleChangeLabel = (val) => setNewLabel(val);
  const isValid = useMemo(() => newLabel && newLabel !== existingLabel);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel,
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Continue',
      onClick: () =>
        onSubmit({
          label: newLabel,
        }),
      disabled: !isValid,
    },
  ];

  return (
    <Modal
      title={EDIT_CLAIM_LABEL_MODAL_TITLE}
      buttons={buttons}
      closeHandler={onCancel}
      id="add_claimant_modal"
    >
      <div>
        <strong>{sprintf(EDIT_CLAIM_LABEL_MODAL_SUBHEAD, existingLabel)}</strong>
      </div>
      <p>{EDIT_CLAIM_LABEL_MODAL_NOTE}</p>
      <SearchableDropdown
        name="claimLabel"
        label="Select the correct EP claim label"
        onChange={handleChangeLabel}
        value={newLabel}
        options={[]}
        debounce={250}
        strongLabel
      />
    </Modal>
  );
};

EditClaimLabelModal.propTypes = {

  /**
   * The claim label that the user wants to change
   */
  existingLabel: PropTypes.string,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
