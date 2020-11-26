import React, { useEffect, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import DateSelector from 'app/components/DateSelector';
import COPY from 'app/../COPY';
import { useDispatch } from 'react-redux';
import { resetSuccessMessages, showSuccessMessage } from '../uiReducer/uiActions';

export const EditNodDateModalContainer = ({ onCancel, onSubmit, nodDate }) => {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(resetSuccessMessages());
  }, []);

  const handleSubmit = () => {
    const successMessage = {
      title: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE,
      detail: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE,
    };

    dispatch(showSuccessMessage(successMessage));
    onSubmit?.();
    window.scrollTo(0, 0);
  };

  return (
    <EditNodDateModal
      onCancel={onCancel}
      onSubmit={handleSubmit}
      nodDate={nodDate}
    />
  );
};

export const EditNodDateModal = ({ onCancel, onSubmit, nodDate }) => {
  const [receiptDate, setReceiptDate] = useState(nodDate);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Submit',
      onClick: () => onSubmit(receiptDate)
    }
  ];

  const handleDateChange = (value) => setReceiptDate(value);

  return (
    <Modal
      title={COPY.EDIT_NOD_DATE_MODAL_TITLE}
      onCancel={onCancel}
      onSubmit={onSubmit}
      closeHandler={onCancel}
      buttons={buttons}>
      <div>
        <ReactMarkdown source={COPY.EDIT_NOD_DATE_MODAL_DESCRIPTION} />
      </div>
      <DateSelector
        label={COPY.EDIT_NOD_DATE_LABEL}
        name="nodDate"
        strongLabel
        type="date"
        value={receiptDate}
        onChange={handleDateChange}
      />
    </Modal>
  );
};

EditNodDateModalContainer.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  nodDate: PropTypes.string.isRequired
};

EditNodDateModal.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  nodDate: PropTypes.string.isRequired
};
