import React, { useEffect, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import DateSelector from 'app/components/DateSelector';
import COPY from 'app/../COPY';
import { useDispatch, useSelector } from 'react-redux';
import { resetSuccessMessages, showSuccessMessage } from '../uiReducer/uiActions';
import { editAppeal } from '../QueueActions';
import ApiUtil from '../../util/ApiUtil';
import moment from 'moment';
import { sprintf } from 'sprintf-js';
import { formatDateStr } from '../../util/DateUtil';
import { appealWithDetailSelector } from '../selectors';

export const EditNodDateModalContainer = ({ onCancel, onSubmit, nodDate, appealId }) => {
  const dispatch = useDispatch();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  useEffect(() => {
    dispatch(resetSuccessMessages());
  }, []);

  const handleSubmit = (receiptDate) => {
    var alertInfo = {
      appellantName: (appeal.appellantFullName),
      nodDateStr: formatDateStr(nodDate, 'YYYY-MM-DD', 'MM/DD/YYYY'),
      receiptDateStr: formatDateStr(receiptDate, 'YYYY-MM-DD', 'MM/DD/YYYY')
    }

    const title = COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE;
    const detail = (sprintf(COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE, alertInfo));

    const successMessage = {
      title,
      detail,
    };
    const payload = { data: { receipt_date: receiptDate } };

    ApiUtil.patch(`/appeals/${appealId}/update_nod_date`, payload).then(() => {
      dispatch(editAppeal(appealId, { nodDate: receiptDate }));
      dispatch(showSuccessMessage(successMessage));
      onSubmit?.();
      window.scrollTo(0, 0);
    });
  };

  return (
    <EditNodDateModal
      onCancel={onCancel}
      onSubmit={handleSubmit}
      nodDate={nodDate}
      appealId={appealId}
      appellantName={appeal.appellantFullName}
    />
  );
};

export const EditNodDateModal = ({ onCancel, onSubmit, nodDate }) => {
  const [receiptDate, setReceiptDate] = useState(nodDate);
  const [disableButton, setDisableButton] = useState(false);
  const [errorMessage, setErrorMessage] = useState(null);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Submit',
      // For future disable use cases
      disabled: disableButton,
      onClick: () => onSubmit(receiptDate)
    }
  ];

  const isFutureDate = (newDate) => {
    const today = new Date();
    const todaysDate = moment(today.toISOString());
    const date = moment(newDate);

    return (date > todaysDate);
  };

  const isPreAmaDate = (newDate) => {
    const formattedNewDate = moment(newDate);
    const amaDate = moment('2019-02-19');

    return (formattedNewDate < amaDate);
  };

  const handleDateChange = (value) => {
    if (isFutureDate(value)) {
      setErrorMessage(COPY.EDIT_NOD_DATE_FUTURE_DATE_ERROR_MESSAGE);
      setDisableButton(true);
      setReceiptDate(value);
    } else if (isPreAmaDate(value)) {
      setErrorMessage(COPY.EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE);
      setDisableButton(true);
      setReceiptDate(value);
    } else {
      setErrorMessage(null);
      setReceiptDate(value);
      setDisableButton(false);
    }
  };

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
        name="nodDate"
        errorMessage={errorMessage}
        label={COPY.EDIT_NOD_DATE_LABEL}
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
