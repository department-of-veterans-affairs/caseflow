import React, { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import DateSelector from 'app/components/DateSelector';
import COPY from 'app/../COPY';
import { useDispatch } from 'react-redux';
import { requestPatch, resetSuccessMessages, showSuccessMessage } from '../uiReducer/uiActions';
import ApiUtil from '../../util/ApiUtil';

export const EditNodDateModalContainer = ({ onCancel, onSubmit, nodDate, appealId, requestPatch }) => {
  const dispatch = useDispatch();

  const handleSubmit = (receiptDate) => {
    const successMessage = {
      title: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE,
      detail: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE,
    };

    ApiUtil.patch(`/appeals/${appealId}/update_nod_date`, { data: { receipt_date: receiptDate } }).then(() => {
      dispatch(showSuccessMessage(successMessage));
      onSubmit?.();
    },
    (error) => {
      console.log(receiptDate);
      console.log(error);
    });
  };

  return (
    <EditNodDateModal
      onCancel={onCancel}
      onSubmit={handleSubmit}
      nodDate={nodDate}
      appealId={appealId}
    />
  );
};

export const EditNodDateModal = ({ onCancel, onSubmit, nodDate, appealId }) => {
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
        name={COPY.EDIT_NOD_DATE_LABEL}
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
  nodDate: PropTypes.string.isRequired,
  appealId: PropTypes.string.isRequired
};

EditNodDateModal.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  nodDate: PropTypes.string.isRequired,
  appealId: PropTypes.string.isRequired
};
