import React, { useState } from 'react';
import Modal from '../../../../components/Modal';
import PropTypes from 'prop-types';
import RadioField from '../../../../components/RadioField';
import Alert from '../../../../components/Alert';

const ReturnToQueueModal = (props) => {
  const [selectedRadio, setSelectedRadio] = useState('');

  const radioOptions = [
    { displayText: 'Cancel intake',
      value: 'cancel_intake' },
    { displayText: 'Continue intake at a later date',
      value: 'continue_later' }
  ];

  const onRadioChange = (value) => {
    setSelectedRadio(value);
  };

  const handleConfirm = () => {
    if (selectedRadio === 'continue_later') {
      props.handleContinueIntakeLater();
    } else if (selectedRadio === 'cancel_intake') {
      props.handleCancelIntake();
    }
  };

  return (
    <Modal
      title="Return To Queue"
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Close',
          onClick: props.onCancel
        },
        {
          classNames: ['usa-button'],
          name: 'Confirm',
          disabled: !selectedRadio,
          onClick: handleConfirm,
        }
      ]}
      closeHandler={props.onCancel}
    >
      <RadioField
        label="Select whether to cancel the intake of this mail package or resume the intake process at a later date."
        name="return-to-queue"
        value={selectedRadio}
        options={radioOptions}
        onChange={onRadioChange}
        vertical
      />
      {selectedRadio === 'continue_later' && <Alert
        message="Saving the intake form to continue it at a later date will
         resume the intake form at step three of the process."
        type="info"
      />}
    </Modal>
  );
};

ReturnToQueueModal.propTypes = {
  onCancel: PropTypes.func,
  handleContinueIntakeLater: PropTypes.func,
  handleCancelIntake: PropTypes.func
};

export default ReturnToQueueModal;
