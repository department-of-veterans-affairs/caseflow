/* eslint-disable no-undefined */
import React, { useState } from 'react';
import { bindActionCreators } from 'redux';
import { connect, useDispatch } from 'react-redux';
import { withRouter } from 'react-router';
import PropTypes from 'prop-types';

import QueueFlowModal from './components/QueueFlowModal';
import { requestPatch, showErrorMessage } from './uiReducer/uiActions';
import { validateDateNotInFuture } from '../intake/util/issues';
import DateSelector from '../components/DateSelector';
import TextareaField from '../components/TextareaField';
import Alert from '../components/Alert';
import CAVC_DECISION_TYPES from '../../constants/CAVC_DECISION_TYPES';
import COPY from '../../COPY';

/**
 * @param {Object} props
 *  - @param {string}   appealId         The id of the appeal we are updating this cavc remand for.
 *  - @param {Object}   error            Error sent from the back end upon submit to be displayed rather than submitting
 *  - @param {boolean}  highlightInvalid Whether or not to show field validation, set to true upon submit
 *  - @param {Object}   history          Provided with react router to be able to route to another page upon success
 */

const AddCavcDatesModal = ({ appealId, decisionType, error, highlightInvalid, history }) => {

  const [judgementDate, setJudgementDate] = useState(null);
  const [mandateDate, setMandateDate] = useState(null);
  const [instructions, setInstructions] = useState(undefined);
  const dispatch = useDispatch();

  const straightReversalType = () => decisionType === CAVC_DECISION_TYPES.straight_reversal;
  const deathDismissalType = () => decisionType === CAVC_DECISION_TYPES.death_dismissal;

  const validJudgementDate = () => Boolean(judgementDate) && validateDateNotInFuture(judgementDate);
  const validMandateDate = () => Boolean(mandateDate) && validateDateNotInFuture(mandateDate);
  const validInstructions = () => instructions?.length > 0;

  const validateForm = () => {
    return validJudgementDate() && validMandateDate() && validInstructions();
  };

  const submit = () => new Promise((resolve) => {
    const payload = {
      data: {
        judgement_date: judgementDate,
        mandate_date: mandateDate,
        remand_appeal_id: appealId,
        instructions,
        source_form: 'add_cavc_dates_modal',
      }
    };

    const successMsgDetail = () => {
      if (straightReversalType() || deathDismissalType()) {
        return COPY.CAVC_REMAND_READY_FOR_DISTRIBUTION_DETAIL;
      }

      return COPY.CAVC_REMAND_CREATED_DETAIL;
    };

    const successMsg = {
      title: COPY.CAVC_REMAND_CREATED_TITLE,
      detail: successMsgDetail()
    };

    dispatch(requestPatch(`/appeals/${appealId}/cavc_remand`, payload, successMsg)).
      then(() => {
        history.replace('/queue');
        resolve();
      }).
      catch((err) => showErrorMessage({ title: 'Error', detail: JSON.parse(err.message).errors[0].detail }));
  });

  const judgementField = <DateSelector
    label={COPY.CAVC_JUDGEMENT_DATE}
    type="date"
    name="judgement-date"
    value={judgementDate}
    onChange={(val) => setJudgementDate(val)}
    errorMessage={highlightInvalid && !validJudgementDate() ? COPY.CAVC_JUDGEMENT_DATE_ERROR : null}
    strongLabel
  />;

  const mandateField = <DateSelector
    label={COPY.CAVC_MANDATE_DATE}
    type="date"
    name="mandate-date"
    value={mandateDate}
    onChange={(val) => setMandateDate(val)}
    errorMessage={highlightInvalid && !validMandateDate() ? COPY.CAVC_MANDATE_DATE_ERROR : null}
    strongLabel
  />;

  const instructionsTextField = <TextareaField
    label={COPY.CAVC_INSTRUCTIONS_LABEL}
    name="context-and-instructions-textBox"
    value={instructions}
    onChange={(val) => setInstructions(val)}
    errorMessage={highlightInvalid && !validInstructions() ? COPY.CAVC_INSTRUCTIONS_ERROR : null}
    strongLabel
  />;

  return (
    <QueueFlowModal
      title={COPY.ADD_CAVC_DATES_TITLE}
      validateForm={validateForm}
      submit={submit}
    >
      <p>{COPY.ADD_CAVC_DESCRIPTION}</p>
      {judgementField}
      {mandateField}
      {instructionsTextField}
      {error && <Alert title={error.title} type="error">{error.detail}</Alert>}
    </QueueFlowModal>
  );
};

AddCavcDatesModal.propTypes = {
  appealId: PropTypes.string,
  decisionType: PropTypes.string,
  requestPatch: PropTypes.func,
  showErrorMessage: PropTypes.func,
  error: PropTypes.object,
  highlightInvalid: PropTypes.bool,
  history: PropTypes.object
};

const mapStateToProps = (state, ownProps) => ({
  highlightInvalid: state.ui.highlightFormItems,
  error: state.ui.messages.error,
  // eslint-disable-next-line camelcase
  decisionType: state.queue.appealDetails[ownProps.appealId].cavcRemand?.cavc_decision_type
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  showErrorMessage
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddCavcDatesModal));
