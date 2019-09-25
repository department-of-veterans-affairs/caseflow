import React, { useState } from 'react';
import PropTypes from 'prop-types';

import { cavcUrl } from '.';
import Modal from '../components/Modal';
import COPY from '../../COPY.json';
import RadioField from '../components/RadioField';

const title = 'Check CAVC for Conflict of Jurisdiction';
const radioOpts = [
  {
    displayText: 'Yes, assign to Litigation Support to determine jurisdiction',
    value: true
  },
  {
    displayText: 'No, continue sending for Dispatch',
    value: false
  }
];

export const PulacCerulloReminderModal = ({ appellantName, onSubmit, onCancel }) => {
  const [hasCavc, setHasCavc] = useState(null);

  const cancelHandler = () => onCancel();
  const submitHandler = () => {
    //   Should we perform / return separate actions? Likely just return the selection
    onSubmit({ hasCavc });
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
        Before sending this case to Dispatch, be sure there is no Notice of Appeal (NOA) on file at the{' '}
        <a href={cavcUrl}>CAVC website</a>.
      </p>
      <p>
        <strong>Does this decision have an NOA on file at CAVC?</strong>
        {appellantName && (
          <div>
            <strong>(Apellant name: {appellantName}</strong>
          </div>
        )}
      </p>
      <RadioField
        name="Which information source shows the correct representative for this appeal?"
        options={radioOpts}
        value={hasCavc}
        onChange={(val) => setHasCavc(val)}
        errorMessage="Field is required"
        required
      />
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
