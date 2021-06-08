import React, { Fragment } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { Redirect } from 'react-router-dom';
import { reject, map } from 'lodash';
import RadioField from '../../components/RadioField';
import ReceiptDateInput from './receiptDateInput';
import { setDocketType } from '../actions/appeal';
import { setReceiptDate, setOptionSelected } from '../actions/intake';
import { setAppealDocket, confirmIneligibleForm } from '../actions/rampRefiling';
import { toggleIneligibleError, convertStringToBoolean } from '../util';
import LegacyOptInApproved from '../components/LegacyOptInApproved';
import {
  setVeteranIsNotClaimant,
  setClaimant,
  setPayeeCode,
  setLegacyOptInApproved,
  setBenefitType,
} from '../actions/decisionReview';
import { setInformalConference, setSameOffice } from '../actions/higherLevelReview';
import { bindActionCreators } from 'redux';
import { getIntakeStatus } from '../selectors';
import SelectClaimant from '../components/SelectClaimant';
import BenefitType from '../components/BenefitType';
import { BOOLEAN_RADIO_OPTIONS, FORM_TYPES, INTAKE_STATES, PAGE_PATHS,
  REQUEST_STATE, REVIEW_OPTIONS, VBMS_BENEFIT_TYPES } from '../constants';

import ErrorAlert from '../components/ErrorAlert';
import COPY from '../../../COPY';
import Alert from '../../components/Alert';
import Button from '../../components/Button';

const docketTypeRadioOptions = [
  { value: 'direct_review',
    displayText: 'Direct Review' },
  { value: 'evidence_submission',
    displayText: 'Evidence Submission' },
  { value: 'hearing',
    displayText: 'Hearing' }
];

const rampElectionReviewOptions = reject(REVIEW_OPTIONS, REVIEW_OPTIONS.APPEAL);

const rampRefilingRadioOptions = map(REVIEW_OPTIONS, (option) => ({
  value: option.key,
  displayText: option.name
}));

const rampElectionRadioOptions = map(rampElectionReviewOptions, (option) => ({
  value: option.key,
  displayText: option.name
}));

const formFieldMapping = (props) => {
  return ({
    'receipt-date': <ReceiptDateInput {...props} />,
    'docket-type': <RadioField
      name="docket-type"
      label="Which review option did the Veteran request?"
      strongLabel
      vertical
      options={docketTypeRadioOptions}
      onChange={props.setDocketType}
      errorMessage={props.docketTypeError || props.errors?.['docket-type']?.message}
      value={props.docketType}
      inputRef={props.register}
    />,
    'legacy-opt-in': <LegacyOptInApproved
      value={props.legacyOptInApproved}
      onChange={props.setLegacyOptInApproved}
      errorMessage={props.legacyOptInApprovedError || props.errors?.['legacy-opt-in']?.message}
      register={props.register}
    />,
    'different-claimant-option': <SelectClaimantConnected
      register={props.register}
      errors={props.errors}
      formName={props.formName}
    />,
    'benefit-type-options': <BenefitType
      value={props.benefitType}
      onChange={props.setBenefitType}
      errorMessage={props.benefitTypeError || props.errors?.['benefit-type-options']?.message}
      register={props.register}
    />,
    'informal-conference': <RadioField
      name="informal-conference"
      label="Was an informal conference requested?"
      strongLabel
      vertical
      options={BOOLEAN_RADIO_OPTIONS}
      onChange={(value) => {
        props.setInformalConference(convertStringToBoolean(value));
      }}
      errorMessage={props.informalConferenceError || props.errors?.['informal-conference']?.message}
      // eslint-disable-next-line no-undefined
      value={props.informalConference === null || props.informalConference === undefined ?
        null : props.informalConference.toString()}
      inputRef={props.register}
    />,
    'same-office': <RadioField
      name="same-office"
      label="Was an interview by the same office requested?"
      strongLabel
      vertical
      options={BOOLEAN_RADIO_OPTIONS}
      onChange={(value) => {
        props.setSameOffice(convertStringToBoolean(value));
      }}
      errorMessage={props.sameOfficeError || props.errors?.['same-office']?.message}
      // eslint-disable-next-line no-undefined
      value={props.sameOffice === null || props.sameOffice === undefined ? null : props.sameOffice.toString()}
      inputRef={props.register}
    />,
    'opt-in-election': <Fragment>
      <RadioField
        name="opt-in-election"
        label="Which review lane did the Veteran select?"
        strongLabel
        options={props.formName === FORM_TYPES.RAMP_REFILING.formName ?
          rampRefilingRadioOptions : rampElectionRadioOptions}
        onChange={props.setOptionSelected}
        errorMessage={props.optionSelectedError || props.errors?.['opt-in-election']?.message}
        value={props.optionSelected}
        inputRef={props.register}
      />
      { props.optionSelected === REVIEW_OPTIONS.APPEAL.key &&
        <RadioField
          name="appeal-docket"
          label="Which type of appeal did the Veteran request?"
          strongLabel
          options={docketTypeRadioOptions}
          onChange={props.setAppealDocket}
          errorMessage={props.appealDocketError || props.errors?.['appeal-docket']?.message}
          value={props.appealDocket}
          inputRef={props.register}
        />
      }
    </Fragment>
  });
};

const FormGenerator = (props) => {
  switch (props.intakeStatus) {
  case INTAKE_STATES.NONE:
    return <Redirect to={PAGE_PATHS.BEGIN} />;
  case INTAKE_STATES.COMPLETED:
    return <Redirect to={PAGE_PATHS.COMPLETED} />;
  default:
  }

  const beginNextIntake = () => {
    props.confirmIneligibleForm(this.props.intakeId);
  };

  const showInvalidVeteranError = !props.veteranValid && VBMS_BENEFIT_TYPES.includes(props.benefitType);

  return (
    <div>
      <h1>
        {props.formHeader(props.veteranName)}
      </h1>

      { toggleIneligibleError(props.hasInvalidOption, props.optionSelected) &&
        <Alert title="Ineligible for Higher-Level Review" type="error" >
          {COPY.INELIGIBLE_HIGHER_LEVEL_REVIEW_ALERT} <br />
          <Button
            name="begin-next-intake"
            onClick={beginNextIntake}
            loading={props.requestState === REQUEST_STATE.IN_PROGRESS}>
            Begin next intake
          </Button>
        </Alert>
      }

      { props.reviewIntakeError && <ErrorAlert {...props.reviewIntakeError} /> }
      { showInvalidVeteranError && <ErrorAlert errorCode="veteran_not_valid" errorData={props.veteranInvalidFields} /> }

      {Object.keys(props.schema.fields).map((field) => formFieldMapping(props)[field])}
    </div>
  );
};

const SelectClaimantConnected = connect(
  (state, props) => {
    const { featureToggles } = state;

    return ({
      isVeteranDeceased: state.intake.veteran.isDeceased,
      veteranIsNotClaimant: state[props.formName].veteranIsNotClaimant,
      veteranIsNotClaimantError: state[props.formName].veteranIsNotClaimantError,
      claimant: state[props.formName].claimant,
      claimantError: state[props.formName].claimantError,
      payeeCode: state[props.formName].payeeCode,
      payeeCodeError: state[props.formName].payeeCodeError,
      relationships: state[props.formName].relationships,
      benefitType: state[props.formName].benefitType,
      formType: state.intake.formType,
      featureToggles
    });
  },
  (dispatch) => bindActionCreators({
    setVeteranIsNotClaimant,
    setClaimant,
    setPayeeCode
  }, dispatch)
)(SelectClaimant);

FormGenerator.propTypes = {
  schema: PropTypes.object.isRequired,
  formHeader: PropTypes.func.isRequired,
  veteranName: PropTypes.string,
  receiptDate: PropTypes.string,
  receiptDateError: PropTypes.string,
  docketType: PropTypes.string,
  docketTypeError: PropTypes.string,
  legacyOptInApproved: PropTypes.bool,
  legacyOptInApprovedError: PropTypes.string,
  reviewIntakeError: PropTypes.object,
  setDocketType: PropTypes.func,
  setReceiptDate: PropTypes.func,
  setLegacyOptInApproved: PropTypes.func,
  appealStatus: PropTypes.string,
  intakeStatus: PropTypes.string,
  veteranValid: PropTypes.bool,
  veteranInvalidFields: PropTypes.object,
  benefitType: PropTypes.string,
  confirmIneligibleForm: PropTypes.string,
  hasInvalidOption: PropTypes.string,
  optionSelected: PropTypes.string,
  requestState: PropTypes.string,
  register: PropTypes.func,
  errors: PropTypes.array
};

export default connect(
  (state, props) => ({
    veteranName: state.intake.veteran.name,
    intakeStatus: getIntakeStatus(state),
    receiptDate: state[props.formName].receiptDate,
    receiptDateError: state[props.formName].receiptDateError,
    docketType: state[props.formName].docketType,
    docketTypeError: state[props.formName].docketTypeError,
    legacyOptInApproved: state[props.formName].legacyOptInApproved,
    legacyOptInApprovedError: state[props.formName].legacyOptInApprovedError,
    benefitType: state[props.formName].benefitType,
    benefitTypeError: state[props.formName].benefitTypeError,
    optionSelected: state[props.formName].optionSelected,
    optionSelectedError: state[props.formName].optionSelectedError,
    informalConference: state[props.formName].informalConference,
    informalConferenceError: state[props.formName].informalConferenceError,
    sameOffice: state[props.formName].sameOffice,
    sameOfficeError: state[props.formName].sameOfficeError,
    appealDocket: state[props.formName].appealDocket,
    appealDocketError: state[props.formName].appealDocketError,
    reviewIntakeError: state[props.formName].requestStatus.reviewIntakeError,
    veteranValid: state[props.formName].veteranValid,
    veteranInvalidFields: state[props.formName].veteranInvalidFields
  }),
  (dispatch) => bindActionCreators({
    setDocketType,
    setReceiptDate,
    setLegacyOptInApproved,
    setInformalConference,
    setSameOffice,
    setBenefitType,
    setOptionSelected,
    setAppealDocket,
    confirmIneligibleForm
  }, dispatch)
)(FormGenerator);
