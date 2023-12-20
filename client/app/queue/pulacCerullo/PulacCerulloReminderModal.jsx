import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import COPY from '../../../COPY';
import RadioField from '../../components/RadioField';
import { CavcLinkInfo } from './CavcLinkInfo';

const title = COPY.PULAC_CERULLO_REMINDER_MODAL_TITLE;
const radioLabel = COPY.PULAC_CERULLO_REMINDER_MODAL_LABEL;
const radioOpts = [
  {
    displayText: COPY.PULAC_CERULLO_REMINDER_MODAL_OPT_FALSE,
    value: 'no'
  },
  {
    displayText: COPY.PULAC_CERULLO_REMINDER_MODAL_OPT_TRUE,
    value: 'yes'
  }
];

export const PulacCerulloReminderModal = ({ onSubmit, onCancel }) => {
  const [hasCavc, setHasCavc] = useState(null);

  const cancelHandler = () => onCancel();
  const submitHandler = () => onSubmit({ hasCavc: hasCavc === 'yes' });

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
      <div style={{ marginBottom: '1em' }}>
        <CavcLinkInfo />
      </div>

      <RadioField
        name="hasCavc"
        label={radioLabel}
        options={radioOpts}
        value={hasCavc}
        onChange={(val) => setHasCavc(val)}
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
