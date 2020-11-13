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

import epClaimTypes from 'constants/EP_CLAIM_TYPES';

export const EditClaimLabelModal = ({ existingEpCode, onCancel, onSubmit }) => {
  // Only EP codes from the same family should be allowed
  const availableOptions = useMemo(() => {
    // Filter out all but the same family (040, 930, etc)
    // eslint-disable-next-line no-unused-vars
    const filtered = Object.entries(epClaimTypes).filter(([code, type]) => {
      return type.family === epClaimTypes[existingEpCode]?.family;
    });

    // Format suitable for SearchableDropdown
    return filtered.map(([label, value]) => ({
      label,
      value,
    }));
  }, [epClaimTypes, existingEpCode]);

  const [newCode, setNewCode] = useState(availableOptions.find((item) => item.label === existingEpCode));
  const handleChangeLabel = (opt) => setNewCode(opt);
  const isValid = useMemo(() => newCode?.label !== existingEpCode);

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
        oldCode: existingEpCode,
        newCode: newCode.label
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
        <strong>
          {
            /* eslint-disable camelcase */
            sprintf(
              EDIT_CLAIM_LABEL_MODAL_SUBHEAD,
            `${epClaimTypes[existingEpCode]?.family} ${
              epClaimTypes[existingEpCode]?.official_label
            }`
            )
          /* eslint-enable camelcase */
          }
        </strong>
      </div>
      <p>{EDIT_CLAIM_LABEL_MODAL_NOTE}</p>
      <SearchableDropdown
        name="claimLabel"
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
  existingEpCode: PropTypes.string.isRequired,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func.isRequired,
};
