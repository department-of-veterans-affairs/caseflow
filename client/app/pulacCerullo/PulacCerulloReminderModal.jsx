import React, { useState } from 'react';
import PropTypes from 'prop-types';

import { cavcUrl } from '.';
import Modal from '../components/Modal';
import COPY from '../../COPY.json';
import RadioField from '../components/RadioField';
import CopyTextButton from '../components/CopyTextButton';

const title = 'Check CAVC for Conflict of Jurisdiction';
const radioOpts = [
  {
    displayText: 'No, continue sending to Dispatch',
    value: 'no'
  },
  {
    displayText: 'Yes, notify Litigation Support of jurisdictional conflict',
    value: 'yes'
  }
];

export const PulacCerulloReminderModal = ({ appellantName, onSubmit, onCancel }) => {
  const [hasCavc, setHasCavc] = useState(null);

  const cancelHandler = () => onCancel();
  const submitHandler = () => {
    //   Should we perform / return separate actions? Likely just return the selection
    onSubmit({ hasCavc: hasCavc === 'yes' });
  };

  return (
    <Modal
      title={title}
      buttons={[
        {
          classNames: ['usa-button', 'cf-btn-link'],
          name: COPY.MODAL_CANCEL_BUTTON,
          onClick: cancelHandler
        },
        {
          classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
          name: 'Submit',
          onClick: submitHandler,
          disabled: hasCavc === null
        }
      ]}
      closeHandler={cancelHandler}
    >
      <p>
        Before sending this case to Dispatch, be sure there is no Notice of Appeal (NOA) on file at the CAVC website.
      </p>
      <p>
        Copy and paste the CAVC webiste link into Internet Explorer{' '}
        <CopyTextButton text={new URL(cavcUrl).hostname} textToCopy={cavcUrl} label="uscourts.cavc.gov" />
      </p>
      <p>
        <strong>Does this decision have an NOA on file at CAVC?</strong>
        {appellantName && (
          <div>
            <strong>(Apellant name: {appellantName}</strong>
          </div>
        )}
      </p>
      <RadioField name="" options={radioOpts} value={hasCavc} onChange={(val) => setHasCavc(val)} />
    </Modal>
  );
};
PulacCerulloReminderModal.propTypes = {
  appellantName: PropTypes.string,
  onSubmit: PropTypes.func,
  onCancel: PropTypes.func
};

PulacCerulloReminderModal.defaultProps = {
  onSubmit: () => {
    // noop
  },
  onCancel: () => {
    // noop
  }
};
