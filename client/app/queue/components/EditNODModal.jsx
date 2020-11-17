import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import ReactMarkdown from 'react-markdown';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import DateSelector from 'app/components/DateSelector';
import COPY from 'app/../COPY';
import { showSuccessMessage, resetSuccessMessages } from '../uiReducer/uiActions';

export const EditNODModal = ({ onCancel, nodDate }) => {
  const [receiptDate, setReceiptDate] = useState(nodDate);
  const dispatch = useDispatch();

  const onSubmit = () => {

    const successMessage = {
      title: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE,
      detail: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE,
    };

    dispatch(showSuccessMessage(successMessage));
    setInterval(() => dispatch(resetSuccessMessages()), 5000);
    onCancel();
  };

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Submit',
      onClick: onSubmit
    }
  ];

  const handleDateChange = (value) => setReceiptDate(value);

  return (
    <Modal
      title={COPY.EDIT_NOD_DATE_MODAL_TITLE}
      onCancel={onCancel}
      closeHandler={onCancel}
      buttons={buttons}>
      <div>
        <ReactMarkdown source={COPY.EDIT_NOD_DATE_MODAL_DESCRIPTION} />
      </div>
      <DateSelector
        name={COPY.EDIT_NOD_DATE_DROPDOWN_LABEL}
        strongLabel
        type="date"
        value={receiptDate}
        onChange={handleDateChange}
      />
    </Modal>
  );
};

EditNODModal.propTypes = {
  onCancel: PropTypes.func.isRequired,
  nodDate: PropTypes.string.isRequired
};
