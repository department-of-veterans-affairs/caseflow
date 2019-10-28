import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import {
  RETURN_TO_LIT_SUPPORT_MODAL_TITLE,
  RETURN_TO_LIT_SUPPORT_MODAL_CONTENT,
  RETURN_TO_LIT_SUPPORT_MODAL_INSTRUCTIONS_LABEL,
  MODAL_CANCEL_BUTTON
} from '../../../COPY.json';
import TextareaField from '../../components/TextareaField';
import StringUtil from '../../util/StringUtil';

export const ReturnToLitSupportModal = ({ onSubmit, onCancel }) => {
  const [instructions, setInstructions] = useState(null);

  const cancelHandler = () => onCancel();
  const submitHandler = () => onSubmit({ instructions });

  return (
    <Modal
      title={RETURN_TO_LIT_SUPPORT_MODAL_TITLE}
      className="return-to-lit-support"
      buttons={[
        {
          classNames: ['usa-button', 'cf-btn-link'],
          name: MODAL_CANCEL_BUTTON,
          onClick: cancelHandler
        },
        {
          classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
          name: 'Submit',
          onClick: submitHandler,
          disabled: instructions === null
        }
      ]}
      closeHandler={cancelHandler}
    >
      <p>{StringUtil.nl2br(RETURN_TO_LIT_SUPPORT_MODAL_CONTENT)}</p>

      <TextareaField
        name="instructions"
        label={RETURN_TO_LIT_SUPPORT_MODAL_INSTRUCTIONS_LABEL}
        onChange={(val) => setInstructions(val)}
        value={instructions}
        className={['mtv-decision-instructions']}
      />
    </Modal>
  );
};

ReturnToLitSupportModal.propTypes = {
  onSubmit: PropTypes.func,
  onCancel: PropTypes.func
};
