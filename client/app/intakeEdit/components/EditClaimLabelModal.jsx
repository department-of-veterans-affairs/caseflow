import React, { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import Modal from 'app/components/Modal';
import SearchableDropdown from 'app/components/SearchableDropdown';
import {
  EDIT_CLAIM_LABEL_MODAL_TITLE,
  EDIT_CLAIM_LABEL_MODAL_SUBHEAD,
  EDIT_CLAIM_LABEL_MODAL_NOTE,
} from 'app/../COPY';

import EP_CLAIM_TYPES from 'constants/EP_CLAIM_TYPES';

export const EditClaimLabelModal = ({ selectedEpCode, onCancel, onSubmit }) => {
  // Only EP codes from the same family should be allowed
  const availableOptions = useMemo(() => {
    // Filter out all but the same family (040, 930, etc)
    // eslint-disable-next-line no-unused-vars
    const filtered = Object.entries(EP_CLAIM_TYPES).filter(([code, type]) => {
      return type.family === EP_CLAIM_TYPES[selectedEpCode]?.family;
    });

    // Format suitable for SearchableDropdown
    return filtered.map(([label, value]) => ({
      label,
      value,
    }));
  }, [EP_CLAIM_TYPES, selectedEpCode]);

  const [newCode, setNewCode] = useState(availableOptions.find((item) => item.label === selectedEpCode));
  const handleChangeLabel = (opt) => setNewCode(opt);
  const isValid = useMemo(() => newCode?.label !== selectedEpCode);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel,
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Continue',
      onClick: () => onSubmit?.({
        oldCode: selectedEpCode,
        newCode: newCode.label
      }),
      disabled: !isValid
    },
  ];

  return (
    <Modal
      title={EDIT_CLAIM_LABEL_MODAL_TITLE}
      buttons={buttons}
      closeHandler={onCancel}
      id="edit-claim-label-modal"
    >
      <div>
        <strong>
          {
            /* eslint-disable camelcase */
            sprintf(
              EDIT_CLAIM_LABEL_MODAL_SUBHEAD,
            `${EP_CLAIM_TYPES[selectedEpCode]?.family} ${
              EP_CLAIM_TYPES[selectedEpCode]?.official_label
            }`
            )
          /* eslint-enable camelcase */
          }
        </strong>
      </div>
      <p>{EDIT_CLAIM_LABEL_MODAL_NOTE}</p>
      <SearchableDropdown
        name="select-claim-label"
        label="Select the correct EP claim label"
        onChange={handleChangeLabel}
        value={newCode}
        options={availableOptions}
        strongLabel
      />
    </Modal>
  );
};

EditClaimLabelModal.propTypes = {

  /**
   * The claim label that the user wants to change
   */
  selectedEpCode: PropTypes.string.isRequired,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func.isRequired,
};
