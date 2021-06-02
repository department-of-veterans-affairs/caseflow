import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';
import ReceiptDateInput from './receiptDateInput';
import { setDocketType } from '../actions/appeal';
import { setReceiptDate } from '../actions/intake';
import LegacyOptInApproved from '../components/LegacyOptInApproved';
import {
  setVeteranIsNotClaimant,
  setClaimant,
  setPayeeCode,
  setLegacyOptInApproved
} from '../actions/decisionReview';
import { bindActionCreators } from 'redux';
import { getIntakeStatus } from '../selectors';
import SelectClaimant from '../components/SelectClaimant';
import BenefitType from '../components/BenefitType';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';
import { convertStringToBoolean } from '../util';

const docketTypeRadioOptions = [
  { value: 'direct_review',
    displayText: 'Direct Review' },
  { value: 'evidence_submission',
    displayText: 'Evidence Submission' },
  { value: 'hearing',
    displayText: 'Hearing' }
];

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
      value={props.informalConference === null ? null : props.informalConference.toString()}
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
      value={props.sameOffice === null ? null : props.sameOffice.toString()}
      inputRef={props.register}
    />
  });
};

const FormGenerator = (props) => {
  return (
    <div>
      <h1>
        {props.formHeader(props.veteranName)}
      </h1>
      {Object.keys(props.schema.fields).map((field) => formFieldMapping(props)[field])}
    </div>
  );
};

const SelectClaimantConnected = connect(
  ({ higherLevelReview, appeal, intake, featureToggles }) => ({
    isVeteranDeceased: intake.veteran.isDeceased,
    veteranIsNotClaimant: higherLevelReview.veteranIsNotClaimant || appeal.veteranIsNotClaimant,
    veteranIsNotClaimantError: higherLevelReview.veteranIsNotClaimantError || appeal.veteranIsNotClaimantError,
    claimant: higherLevelReview.claimant || appeal.claimant,
    claimantError: higherLevelReview.claimantError || appeal.claimantError,
    payeeCode: higherLevelReview.payeeCode || appeal.payeeCode,
    relationships: higherLevelReview.relationships || appeal.relationships,
    benefitType: higherLevelReview.benefitType || appeal.benefitType,
    formType: intake.formType,
    featureToggles
  }),
  (dispatch) => bindActionCreators({
    setVeteranIsNotClaimant,
    setClaimant,
    setPayeeCode
  }, dispatch)
)(SelectClaimant);

FormGenerator.propTypes = {
  formHeader: PropTypes.string,
  schema: PropTypes.object,
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
  register: PropTypes.func,
  errors: PropTypes.array
};

export default connect(
  (state, props) => ({
    veteranName: state.intake.veteran.name,
    appealStatus: getIntakeStatus(state),
    higherLevelReviewStatus: getIntakeStatus(state),
    receiptDate: state[props.formName].receiptDate,
    receiptDateError: state[props.formName].receiptDateError,
    docketType: state[props.formName].docketType,
    docketTypeError: state[props.formName].docketTypeError,
    legacyOptInApproved: state[props.formName].legacyOptInApproved,
    benefitType: state[props.formName].benefitType,
    benefitTypeError: state[props.formName].benefitTypeError,
    legacyOptInApprovedError: state[props.formName].legacyOptInApprovedError,
    informalConference: state[props.formName].informalConference,
    informalConferenceError: state[props.formName].informalConferenceError,
    sameOffice: state[props.formName].sameOffice,
    sameOfficeError: state[props.formName].sameOfficeError,
    reviewIntakeError: state[props.formName].requestStatus.reviewIntakeError,
    veteranValid: state[props.formName].veteranValid,
    veteranInvalidFields: state[props.formName].veteranInvalidFields
  }),
  (dispatch) => bindActionCreators({
    setDocketType,
    setReceiptDate,
    setLegacyOptInApproved
  }, dispatch)
)(FormGenerator);
