/* eslint-disable camelcase */

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

export const shapeAddressBlock = (entity) => {
  if (
    entity?.listedAttorney?.value &&
    entity?.listedAttorney?.value !== 'not_listed'
  ) {
    const [title, firstName, middleName, lastName] = entity.listedAttorney?.label.split(' ');
    const addressLine1 = entity.listedAttorney?.address.address_line_1;
    const addressLine2 = entity.listedAttorney?.address.address_line_2;
    const addressLine3 = entity.listedAttorney?.address.address_line_3;

    return {
      ...entity,
      title,
      firstName,
      middleName,
      lastName,
      addressLine1,
      addressLine2,
      addressLine3,
      ...entity.listedAttorney.address,
    };
  }

  return entity;
};

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

  const showPoa = poa && !isEmpty(poa);
  const claimantEntity = useMemo(() => shapeAddressBlock(claimant), [claimant]);
  const poaEntity = useMemo(() => shapeAddressBlock(poa), [poa]);

  const missingLastName = useMemo(
    () => claimantEntity?.firstName && !claimantEntity?.lastName,
    [claimantEntity]
  );

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
        <AddressBlock entity={claimantEntity} />
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
        {showPoa && <AddressBlock entity={poaEntity} />}
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
