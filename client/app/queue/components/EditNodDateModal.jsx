import React, { useEffect, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import DateSelector from 'app/components/DateSelector';
import COPY from 'app/../COPY';
import { useDispatch, useSelector } from 'react-redux';
import { Controller, useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import {
  resetSuccessMessages,
  showSuccessMessage,
} from '../uiReducer/uiActions';
import { editAppeal, editNodDateUpdates } from '../QueueActions';
import ApiUtil from '../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import { formatDateStr, DateString } from '../../util/DateUtil';
import { appealWithDetailSelector } from '../selectors';
import Alert from 'app/components/Alert';
import SearchableDropdown from 'app/components/SearchableDropdown';

const alertStyling = css({
  marginBottom: '2em',
  '& .usa-alert-text': { lineHeight: '1' },
});

export const changeReasons = [
  { label: 'New Form/Information Received', value: 'new_info' },
  { label: 'Data Entry Error', value: 'entry_error' },
];

export const EditNodDateModalContainer = ({ onCancel,
  onSubmit,
  nodDate: origNodDate,
  appealId,
  reason: origReason }) => {
  const [showTimelinessError, setTimelinessError] = useState(false);
  const [issues, setIssues] = useState(null);

  const dispatch = useDispatch();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  useEffect(() => {
    dispatch(resetSuccessMessages());
  }, []);

  const handleCancel = () => onCancel();

  const handleSubmit = ({ nodDate, reason }) => {
    const alertInfo = {
      appellantName: appeal.appellantFullName,
      nodDateStr: formatDateStr(origNodDate, 'YYYY-MM-DD', 'MM/DD/YYYY'),
      receiptDateStr: formatDateStr(nodDate, 'YYYY-MM-DD', 'MM/DD/YYYY'),
    };

    const title = COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE;
    const detail = sprintf(COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE, alertInfo);

    const successMessage = {
      title,
      detail,
    };
    const payload = {
      data: {
        receipt_date: nodDate,
        change_reason: reason,
      },
    };

    ApiUtil.patch(`/appeals/${appealId}/nod_date_update`, payload).then((data) => {
      dispatch(editAppeal(appealId, {
        nodDate: data.body.nodDate,
        docketNumber: data.body.docketNumber,
        reason: data.body.changeReason
      }));

      if (data.body.affectedIssues) {
        setIssues({ affectedIssues: data.body.affectedIssues, unaffectedIssues: data.body.unaffectedIssues });
        setTimelinessError(true);
      } else {
        dispatch(editNodDateUpdates(appealId, data.body.nodDateUpdate));
        dispatch(showSuccessMessage(successMessage));
        onSubmit?.();
        window.scrollTo(0, 0);
      }
    });
  };

  return (
    <EditNodDateModal
      onCancel={handleCancel}
      onSubmit={handleSubmit}
      nodDate={origNodDate}
      reason={origReason}
      appealId={appealId}
      appellantName={appeal.appellantFullName}
      showTimelinessError={showTimelinessError}
      issues={issues}
    />
  );
};

export const EditNodDateModal = ({
  onCancel,
  onSubmit,
  nodDate,
  reason,
  showTimelinessError,
  issues
}) => {
  const [showWarning, setWarning] = useState(false);

  yup.addMethod(yup.date, 'isLater', function () {
    return this.test((value) => {
      const formattedValue = formatDateStr(value, 'YYYY-MM-DD', 'YYYY-MM-DD');
      const formattedNodDate = formatDateStr(nodDate, 'YYYY-MM-DD', 'YYYY-MM-DD');

      if (formattedValue > formattedNodDate) {
        setWarning(true);
      } else {
        setWarning(false);
      }

      return value;
    });
  });

  const schema = yup.object().shape({
    nodDate: yup.
      date().
      min('2018-01-01', COPY.EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE).
      max(new Date(), COPY.EDIT_NOD_DATE_FUTURE_DATE_ERROR_MESSAGE).
      isLater().
      typeError('Invalid date.').
      required(),
    reason: yup.
      string().
      typeError('Required.').
      required().
      oneOf(changeReasons.map((changeReason) => changeReason.value))
  });

  const { register, errors, control, handleSubmit } = useForm(
    {
      defaultValues: { nodDate, reason },
      resolver: yupResolver(schema),
      mode: 'onChange',
      reValidateMode: 'onChange'
    }
  );

  const buttons = [];

  if (!showTimelinessError) {
    buttons.push({
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    });
  }

  buttons.push({
    classNames: ['usa-button', 'usa-button-primary'],
    name: showTimelinessError ? 'Close' : 'Submit',
    onClick: showTimelinessError ? onCancel : handleSubmit(onSubmit)
  });

  let modalContent;

  if (showTimelinessError) {
    modalContent = <div>
      { showTimelinessError ? <Alert
        message={COPY.EDIT_NOD_DATE_TIMELINESS_ERROR_MESSAGE}
        styling={alertStyling}
        title={COPY.EDIT_NOD_DATE_TIMELINESS_ALERT_TITLE}
        type="error"
        scrollOnAlert={false}
      /> : null }

      <strong>Affected Issue(s)</strong>
      <ul className="cf-error">
        {issues.affectedIssues.map((issue) => {

          return <li key={issue.id}>
            {issue.description}
            <div>
              (Decision Date: <DateString date={issue.approx_decision_date} dateFormat = "MM/DD/YYYY" />)
            </div>
          </li>;
        })}
      </ul>

      { issues.unaffectedIssues.length > 0 && <strong>Unaffected Issue(s)</strong> }
      <ul>
        {issues.unaffectedIssues.map((issue) => {

          return <li key={issue.id}>
            {issue.description}
            <div>
              (Decision Date: <DateString date={issue.approx_decision_date} dateFormat = "MM/DD/YYYY" />)
            </div>
          </li>;
        })}
      </ul>
      <br />
      <div>
        <ReactMarkdown source={COPY.EDIT_NOD_DATE_TIMELINESS_COB_MESSAGE} />
      </div>
    </div>;
  } else {
    modalContent = <div>
      <div>
        <ReactMarkdown source={COPY.EDIT_NOD_DATE_MODAL_DESCRIPTION} />
      </div>
      { showWarning ? <Alert
        message={COPY.EDIT_NOD_DATE_WARNING_ALERT_MESSAGE}
        styling={alertStyling}
        title=""
        type="info"
        scrollOnAlert={false}
      /> : null }
      <form onSubmit={handleSubmit(onSubmit)}>
        <DateSelector
          inputRef={register}
          name="nodDate"
          errorMessage={errors.nodDate?.message}
          label={COPY.EDIT_NOD_DATE_LABEL}
          strongLabel
        />
        <Controller
          name="reason"
          control={control}
          defaultValue={null}
          render={({ onChange, ...rest }) => (
            <SearchableDropdown
              {...rest}
              label="Reason for edit"
              errorMessage={errors.reason?.message}
              placeholder="Select the reason..."
              options={changeReasons}
              debounce={250}
              strongLabel
              onChange={(valObj) => onChange(valObj?.value)}
            />
          )}
        />
      </form>
    </div>;
  }

  return (
    <Modal
      title={COPY.EDIT_NOD_DATE_MODAL_TITLE}
      onCancel={onCancel}
      onSubmit={onSubmit}
      closeHandler={onCancel}
      buttons={buttons}>
      {modalContent}
    </Modal>
  );
};

EditNodDateModalContainer.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  onClose: PropTypes.func,
  nodDate: PropTypes.string.isRequired,
  reason: PropTypes.object,
  appealId: PropTypes.string.isRequired,
};

EditNodDateModal.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  onClose: PropTypes.func,
  nodDate: PropTypes.string.isRequired,
  reason: PropTypes.object,
  appealId: PropTypes.string.isRequired,
  showTimelinessError: PropTypes.bool.isRequired,
  issues: PropTypes.object
};
