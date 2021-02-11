import React from 'react';
import PropTypes from 'prop-types';

import { css } from 'glamor';

import Modal from 'app/components/Modal';

import {
  ADD_CLAIMANT_CONFIRM_MODAL_TITLE,
  ADD_CLAIMANT_CONFIRM_MODAL_DESCRIPTION,
  ADD_CLAIMANT_CONFIRM_MODAL_NO_POA,
} from 'app/../COPY';
import { claimantPropTypes, poaPropTypes } from './utils';
import { AddressBlock } from './AddressBlock';

const classes = {
  addressHeader: css({ margin: '1.6rem 0' }),
};

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

      <section>
        <div className={classes.addressHeader}>
          <strong>Claimant</strong>
        </div>
        <AddressBlock entity={claimant} />
      </section>

      <section>
        <div className={classes.addressHeader}>
          <strong>Claimant's POA</strong>
        </div>

        {!poa && <div>{ADD_CLAIMANT_CONFIRM_MODAL_NO_POA}</div>}
        {poa && <AddressBlock entity={poa} />}
      </section>
    </Modal>
  );
};

AddClaimantConfirmationModal.propTypes = {
  claimant: PropTypes.shape(claimantPropTypes),
  poa: PropTypes.shape(poaPropTypes),
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
};
