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

const FormGenerator = (props) => {
  return(
    <div>
      <h1>
        {props.formHeader(props.veteranName)}
      </h1>
      {Object.keys(props.schema.fields).map((field) => formFieldMapping(props)[field])}
    </div>
  )
}

const docketTypeRadioOptions = [
  { value: 'direct_review',
    displayText: 'Direct Review' },
  { value: 'evidence_submission',
    displayText: 'Evidence Submission' },
  { value: 'hearing',
    displayText: 'Hearing' }
];

const formFieldMapping = (props) => ({
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
  />
})

const SelectClaimantConnected = connect(
  ({ appeal, intake, featureToggles }) => ({
    isVeteranDeceased: intake.veteran.isDeceased,
    veteranIsNotClaimant: appeal.veteranIsNotClaimant,
    veteranIsNotClaimantError: appeal.veteranIsNotClaimantError,
    claimant: appeal.claimant,
    claimantError: appeal.claimantError,
    payeeCode: appeal.payeeCode,
    relationships: appeal.relationships,
    benefitType: appeal.benefitType,
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
  schema: PropTypes.object
}

export default connect(
  (state) => console.log(state) || ({
    veteranName: state.intake.veteran.name,
    appealStatus: getIntakeStatus(state),
    receiptDate: state.appeal.receiptDate,
    receiptDateError: state.appeal.receiptDateError,
    docketType: state.appeal.docketType,
    docketTypeError: state.appeal.docketTypeError,
    legacyOptInApproved: state.appeal.legacyOptInApproved,
    legacyOptInApprovedError: state.appeal.legacyOptInApprovedError,
    reviewIntakeError: state.appeal.requestStatus.reviewIntakeError
  }),
  (dispatch) => bindActionCreators({
    setDocketType,
    setReceiptDate,
    setLegacyOptInApproved
  }, dispatch)
)(FormGenerator);