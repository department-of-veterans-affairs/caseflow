import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../../../components/Modal';
import {
  MTV_CHECKOUT_RETURN_TO_JUDGE_MODAL_TITLE,
  MTV_CHECKOUT_RETURN_TO_JUDGE_MODAL_DESCRIPTION,
  PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL,
  MODAL_CANCEL_BUTTON
} from '../../../../../COPY';
import StringUtil from '../../../../util/StringUtil';
import TextareaField from '../../../../components/TextareaField';
import { noop } from 'lodash';

export const ReturnToJudgeModal = ({
  onSubmit = noop,
  onCancel = noop,
  instructions: defaultInstructions = '',
  submitting = false
}) => {
  const [instructions, setInstructions] = useState(defaultInstructions);

  const cancelHandler = () => onCancel();
  const submitHandler = () => onSubmit({ instructions });

  const isValid = () => Boolean(instructions.trim());

  return (
    <Modal
      title={MTV_CHECKOUT_RETURN_TO_JUDGE_MODAL_TITLE}
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
          disabled: !isValid() || submitting
        }
      ]}
      closeHandler={cancelHandler}
    >
      <p>{StringUtil.nl2br(MTV_CHECKOUT_RETURN_TO_JUDGE_MODAL_DESCRIPTION)}</p>

      <TextareaField
        name="instructions"
        label={`${PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}:`}
        strongLabel
        onChange={(val) => setInstructions(val)}
        value={instructions}
        className={['mtv-decision-instructions']}
      />
    </Modal>
  );
};

ReturnToJudgeModal.propTypes = {
  onSubmit: PropTypes.func,
  onCancel: PropTypes.func,
  instructions: PropTypes.string,
  submitting: PropTypes.bool
};
