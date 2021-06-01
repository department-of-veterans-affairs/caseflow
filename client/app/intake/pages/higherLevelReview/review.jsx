import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';
import * as yup from 'yup';
import RadioField from '../../../components/RadioField';
import BenefitType from '../../components/BenefitType';
import LegacyOptInApproved from '../../components/LegacyOptInApproved';
import SelectClaimant, { selectClaimantValidations } from '../../components/SelectClaimant';
import { setInformalConference, setSameOffice } from '../../actions/higherLevelReview';
import {
  setBenefitType,
  setVeteranIsNotClaimant,
  setClaimant,
  setPayeeCode,
  setLegacyOptInApproved
} from '../../actions/decisionReview';
import { setReceiptDate } from '../../actions/intake';
import { PAGE_PATHS, INTAKE_STATES, BOOLEAN_RADIO_OPTIONS,
  FORM_TYPES, VBMS_BENEFIT_TYPES, GENERIC_FORM_ERRORS } from '../../constants';
import { convertStringToBoolean } from '../../util';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';
import PropTypes from 'prop-types';
import ReceiptDateInput, { receiptDateInputValidation } from '../receiptDateInput';

const reviewHigherLevelReviewSchema = yup.object().shape({
  'benefit-type-options': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'informal-conference': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'same-office': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'different-claimant-option': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'legacy-opt-in': yup.string().required(GENERIC_FORM_ERRORS.blank),
  ...selectClaimantValidations(),
  ...receiptDateInputValidation()
});

class Review extends React.PureComponent {
  render() {
    const {
      higherLevelReviewStatus,
      veteranName,
      benefitType,
      benefitTypeError,
      informalConference,
      informalConferenceError,
      sameOffice,
      sameOfficeError,
      legacyOptInApproved,
      legacyOptInApprovedError,
      reviewIntakeError,
      veteranValid,
      veteranInvalidFields,
      errors
    } = this.props;

    switch (higherLevelReviewStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    const showInvalidVeteranError = !veteranValid && VBMS_BENEFIT_TYPES.includes(benefitType);

    return <div>
      <h1>Review { veteranName }'s { FORM_TYPES.HIGHER_LEVEL_REVIEW.name }</h1>

      { reviewIntakeError && <ErrorAlert {...reviewIntakeError} /> }
      { showInvalidVeteranError && <ErrorAlert errorCode="veteran_not_valid" errorData={veteranInvalidFields} /> }

      <BenefitType
        value={benefitType}
        onChange={this.props.setBenefitType}
        errorMessage={benefitTypeError || errors?.['benefit-type-options']?.message}
        register={this.props.register}
      />

      <ReceiptDateInput
        {...this.props}
      />

      <RadioField
        name="informal-conference"
        label="Was an informal conference requested?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={(value) => {
          this.props.setInformalConference(convertStringToBoolean(value));
        }}
        errorMessage={informalConferenceError || errors?.['informal-conference']?.message}
        value={informalConference === null ? null : informalConference.toString()}
        inputRef={this.props.register}
      />

      <RadioField
        name="same-office"
        label="Was an interview by the same office requested?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={(value) => {
          this.props.setSameOffice(convertStringToBoolean(value));
        }}
        errorMessage={sameOfficeError || errors?.['same-office']?.message}
        value={sameOffice === null ? null : sameOffice.toString()}
        inputRef={this.props.register}
      />

      <SelectClaimantConnected
        register={this.props.register}
        errors={this.props.errors}
      />

      <LegacyOptInApproved
        value={legacyOptInApproved}
        onChange={this.props.setLegacyOptInApproved}
        errorMessage={legacyOptInApprovedError || errors?.['legacy-opt-in']?.message}
        register={this.props.register}
      />
    </div>;
  }
}

Review.propTypes = {
  veteranName: PropTypes.string,
  receiptDate: PropTypes.string,
  receiptDateError: PropTypes.string,
  benefitType: PropTypes.string,
  benefitTypeError: PropTypes.string,
  informalConference: PropTypes.bool,
  informalConferenceError: PropTypes.string,
  sameOffice: PropTypes.string,
  sameOfficeError: PropTypes.string,
  legacyOptInApproved: PropTypes.string,
  legacyOptInApprovedError: PropTypes.string,
  reviewIntakeError: PropTypes.object,
  veteranValid: PropTypes.bool,
  veteranInvalidFields: PropTypes.object,
  setBenefitType: PropTypes.func,
  setReceiptDate: PropTypes.func,
  setInformalConference: PropTypes.func,
  setSameOffice: PropTypes.func,
  setLegacyOptInApproved: PropTypes.func,
  higherLevelReviewStatus: PropTypes.string,
  register: PropTypes.func,
  errors: PropTypes.array
};

const SelectClaimantConnected = connect(
  ({ higherLevelReview, intake, featureToggles }) => ({
    isVeteranDeceased: intake.veteran.isDeceased,
    veteranIsNotClaimant: higherLevelReview.veteranIsNotClaimant,
    veteranIsNotClaimantError: higherLevelReview.veteranIsNotClaimantError,
    claimant: higherLevelReview.claimant,
    claimantError: higherLevelReview.claimantError,
    payeeCode: higherLevelReview.payeeCode,
    payeeCodeError: higherLevelReview.payeeCodeError,
    relationships: higherLevelReview.relationships,
    benefitType: higherLevelReview.benefitType,
    formType: intake.formType,
    featureToggles
  }),
  (dispatch) => bindActionCreators({
    setVeteranIsNotClaimant,
    setClaimant,
    setPayeeCode
  }, dispatch)
)(SelectClaimant);

export default connect(
  (state) => ({
    veteranName: state.intake.veteran.name,
    higherLevelReviewStatus: getIntakeStatus(state),
    receiptDate: state.higherLevelReview.receiptDate,
    receiptDateError: state.higherLevelReview.receiptDateError,
    benefitType: state.higherLevelReview.benefitType,
    benefitTypeError: state.higherLevelReview.benefitTypeError,
    legacyOptInApproved: state.higherLevelReview.legacyOptInApproved,
    legacyOptInApprovedError: state.higherLevelReview.legacyOptInApprovedError,
    informalConference: state.higherLevelReview.informalConference,
    informalConferenceError: state.higherLevelReview.informalConferenceError,
    sameOffice: state.higherLevelReview.sameOffice,
    sameOfficeError: state.higherLevelReview.sameOfficeError,
    reviewIntakeError: state.higherLevelReview.requestStatus.reviewIntakeError,
    veteranValid: state.higherLevelReview.veteranValid,
    veteranInvalidFields: state.higherLevelReview.veteranInvalidFields
  }),
  (dispatch) => bindActionCreators({
    setInformalConference,
    setSameOffice,
    setReceiptDate,
    setBenefitType,
    setLegacyOptInApproved
  }, dispatch)
)(Review);

export { reviewHigherLevelReviewSchema };
