import React, { useEffect, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import { css } from 'glamor';
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
import Alert from 'app/components/Alert';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { marginTop } from '../constants';

const alertStyling = css({
  marginBottom: '2em',
  '& .usa-alert-text': { lineHeight: '1' }
});

export const changeReasons = [
  { label: 'New Form/Information Received', value: 'new_info' },
  { label: 'Data Entry Error', value: 'entry_error' },
];

export const EditNodDateModalContainer = ({ onCancel, onSubmit, nodDate, appealId, reason }) => {
  const dispatch = useDispatch();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  useEffect(() => {
    dispatch(resetSuccessMessages());
  }, []);

  const handleSubmit = (receiptDate, changeReason) => {
    const alertInfo = {
      appellantName: (appeal.appellantFullName),
      nodDateStr: formatDateStr(nodDate, 'YYYY-MM-DD', 'MM/DD/YYYY'),
      receiptDateStr: formatDateStr(receiptDate, 'YYYY-MM-DD', 'MM/DD/YYYY')
    };

    const title = COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE;
    const detail = (sprintf(COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE, alertInfo));

    const successMessage = {
      title,
      detail,
    };
    const payload = {
      data: {
        receipt_date: receiptDate,
        change_reason: changeReason.value
      }
    };

    ApiUtil.patch(`/appeals/${appealId}/nod_date_update`, payload).then((data) => {
      dispatch(editAppeal(appealId, {
        nodDate: data.body.nodDate,
        docketNumber: data.body.docketNumber,
        reason: data.body.changeReason
      }));
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
      reason={reason}
      appealId={appealId}
      appellantName={appeal.appellantFullName}
    />
  );
};

export const EditNodDateModal = ({ onCancel, onSubmit, nodDate, reason }) => {
  const [receiptDate, setReceiptDate] = useState(nodDate);
  const [changeReason, setChangeReason] = useState(reason);
  const [errorMessage, setErrorMessage] = useState(null);
  const [showWarning, setWarningMessage] = useState(false);
  const [badDate, setBadDate] = useState(null);
  const [badReason, setBadReason] = useState(true);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Submit',
      disabled: (badDate || badReason),
      onClick: () => onSubmit(receiptDate, changeReason)
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

  const isLaterThanNodDate = (newDate) => {
    const formattedNewDate = moment(newDate);
    const formattedNodDate = moment(nodDate);

    return (formattedNewDate > formattedNodDate);
  };

  const handleDateChange = (value) => {
    if (isFutureDate(value)) {
      setWarningMessage(false);
      setErrorMessage(COPY.EDIT_NOD_DATE_FUTURE_DATE_ERROR_MESSAGE);
      setReceiptDate(value);
      setBadDate(true);
    } else if (isPreAmaDate(value)) {
      setWarningMessage(false);
      setErrorMessage(COPY.EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE);
      setReceiptDate(value);
      setBadDate(true);
    } else if (isLaterThanNodDate(value)) {
      setWarningMessage(true);
      setErrorMessage(null);
      setReceiptDate(value);
      setBadDate(false);
    } else {
      setWarningMessage(false);
      setErrorMessage(null);
      setReceiptDate(value);
      setBadDate(null);
    }
  };

  const handleChangeReason = (value) => {
    if (!value === null) {
      setBadReason(true);
    } else {
      setChangeReason(value);
      setBadReason(null);
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
      { showWarning ? <Alert
        message={COPY.EDIT_NOD_DATE_WARNING_ALERT_MESSAGE}
        styling={alertStyling}
        title=""
        type="info"
        scrollOnAlert= {false}
      /> : null }
      <DateSelector
        style={marginTop}
        name="nodDate"
        errorMessage={errorMessage}
        label={COPY.EDIT_NOD_DATE_LABEL}
        strongLabel
        type="date"
        value={receiptDate}
        onChange={handleDateChange}
      />
      <SearchableDropdown
        name="reason"
        label="Reason for edit"
        searchable={false}
        placeholder="Select the reason..."
        value={changeReason}
        options={changeReasons}
        onChange={handleChangeReason}
        debounce={250}
        strongLabel
      />
    </Modal>
  );
};

EditNodDateModalContainer.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  nodDate: PropTypes.string.isRequired,
  reason: PropTypes.object,
  appealId: PropTypes.string.isRequired
};

EditNodDateModal.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  nodDate: PropTypes.string.isRequired,
  reason: PropTypes.object,
  appealId: PropTypes.string.isRequired
};
