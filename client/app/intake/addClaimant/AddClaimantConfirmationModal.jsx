import React, { useMemo } from 'react';
import PropTypes from 'prop-types';

import { css } from 'glamor';

import Modal from 'app/components/Modal';
import Alert from 'app/components/Alert';

import {
  ADD_CLAIMANT_CONFIRM_MODAL_TITLE,
  ADD_CLAIMANT_CONFIRM_MODAL_DESCRIPTION,
  ADD_CLAIMANT_CONFIRM_MODAL_NO_POA,
  ADD_CLAIMANT_CONFIRM_MODAL_LAST_NAME_ALERT,
} from 'app/../COPY';
import { claimantPropTypes, poaPropTypes } from './utils';
import { AddressBlock } from './AddressBlock';
import { isEmpty } from 'lodash';

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
      name: 'Confirm',
      onClick: onConfirm,
      disabled: false,
    },
  ];

  const missingLastName = useMemo(
    () => claimant?.partyType === 'individual' && !claimant?.lastName,
    [claimant]
  );

  const showPoa = poa && !isEmpty(poa);

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
        {missingLastName && (
          <Alert
            message={ADD_CLAIMANT_CONFIRM_MODAL_LAST_NAME_ALERT}
            type="warning"
          />
        )}
      </section>

      <section>
        <div className={classes.addressHeader}>
          <strong>Claimant's POA</strong>
        </div>

        {!showPoa && <div>{ADD_CLAIMANT_CONFIRM_MODAL_NO_POA}</div>}
        {showPoa && <AddressBlock entity={poa} />}
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
