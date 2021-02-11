import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';

import {
  ADD_CLAIMANT_CONFIRM_MODAL_TITLE,
  ADD_CLAIMANT_CONFIRM_MODAL_DESCRIPTION,
} from 'app/../COPY';
import { claimantPropTypes, poaPropTypes } from './utils';

export const AddClaimantConfirmationModal = ({
  claimant,
  poa,
  onCancel,
  onConfirm,
}) => {
  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel and edit',
      onClick: onCancel,
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Add this claimant',
      onClick: onConfirm,
      disabled: false,
    },
  ];

  return (
    <Modal
      title={ADD_CLAIMANT_CONFIRM_MODAL_TITLE}
      buttons={buttons}
      closeHandler={onCancel}
      id="add_claimant_modal"
    >
      <p>{ADD_CLAIMANT_CONFIRM_MODAL_DESCRIPTION}</p>

      <div>
        <p>
          <strong>Claimant</strong>
        </p>
        {claimant.partyType === 'organization' && (
          <div>{claimant.organization}</div>
        )}
        {claimant.partyType === 'individual' && (
          <div>{`${claimant.firstName} ${claimant.middleName} ${
            claimant.lastName
          }`}</div>
        )}
        <div>{claimant.address1}</div>
        {claimant.address2 && <div>{claimant.address2}</div>}
        {claimant.address3 && <div>{claimant.address3}</div>}
        <div>
          {`${claimant.city}, ${claimant.state} ${claimant.country} ${claimant.zip}`}
        </div>
        {claimant.phoneNumber && <div>{claimant.phoneNumber}</div>}
      </div>
    </Modal>
  );
};

AddClaimantConfirmationModal.propTypes = {
  claimant: PropTypes.shape(claimantPropTypes),
  poa: PropTypes.shape(poaPropTypes),
};
