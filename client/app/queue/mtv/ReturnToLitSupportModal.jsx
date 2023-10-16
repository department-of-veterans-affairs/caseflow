import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import {
  RETURN_TO_LIT_SUPPORT_MODAL_TITLE,
  RETURN_TO_LIT_SUPPORT_MODAL_CONTENT,
  PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL,
  RETURN_TO_LIT_SUPPORT_MODAL_DEFAULT_INSTRUCTIONS,
  MODAL_CANCEL_BUTTON
} from '../../../COPY';
import TextareaField from '../../components/TextareaField';
import StringUtil from '../../util/StringUtil';

export const ReturnToLitSupportModal = ({
  onSubmit,
  onCancel,
  instructions: defaultInstructions = RETURN_TO_LIT_SUPPORT_MODAL_DEFAULT_INSTRUCTIONS
}) => {
  const [instructions, setInstructions] = useState(defaultInstructions);

  const cancelHandler = () => onCancel();
  const submitHandler = () => onSubmit({ instructions });

  const isValid = () => Boolean(instructions.trim());

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
          disabled: !isValid()
        }
      ]}
      closeHandler={cancelHandler}
    >
      <p>{StringUtil.nl2br(RETURN_TO_LIT_SUPPORT_MODAL_CONTENT)}</p>

      <TextareaField
        name="instructions"
        label={PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}
        onChange={(val) => setInstructions(val)}
        value={instructions}
        className={['mtv-decision-instructions']}
      />
    </Modal>
  );
};

ReturnToLitSupportModal.propTypes = {
  onSubmit: PropTypes.func,
  onCancel: PropTypes.func,
  instructions: PropTypes.string
};
