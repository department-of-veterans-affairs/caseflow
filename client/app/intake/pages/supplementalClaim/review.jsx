import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import * as yup from 'yup';
import { Redirect } from 'react-router-dom';
import BenefitType from '../../components/BenefitType';
import LegacyOptInApproved from '../../components/LegacyOptInApproved';
import SelectClaimant, { selectClaimantValidations } from '../../components/SelectClaimant';
import {
  setBenefitType,
  setVeteranIsNotClaimant,
  setClaimant,
  setPayeeCode,
  setLegacyOptInApproved
} from '../../actions/decisionReview';
import { setReceiptDate } from '../../actions/intake';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES, VBMS_BENEFIT_TYPES, GENERIC_FORM_ERRORS } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';
import PropTypes from 'prop-types';
import ReceiptDateInput, { receiptDateInputValidation } from '../receiptDateInput';

const reviewSupplementalClaimSchema = yup.object().shape({
  'benefit-type-options': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'different-claimant-option': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'legacy-opt-in': yup.string().required(GENERIC_FORM_ERRORS.blank),
  ...selectClaimantValidations(),
  ...receiptDateInputValidation()
});

class Review extends React.PureComponent {
  render() {
    const {
      supplementalClaimStatus,
      veteranName,
      benefitType,
      benefitTypeError,
      legacyOptInApproved,
      legacyOptInApprovedError,
      reviewIntakeError,
      veteranValid,
      veteranInvalidFields,
      errors
    } = this.props;

    switch (supplementalClaimStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    const showInvalidVeteranError = !veteranValid && VBMS_BENEFIT_TYPES.includes(benefitType);

    return <div>
      <h1>Review { veteranName }'s { FORM_TYPES.SUPPLEMENTAL_CLAIM.name }</h1>

      { reviewIntakeError && <ErrorAlert {...reviewIntakeError} /> }
      { showInvalidVeteranError &&
          <ErrorAlert
            errorUUID={this.props.errorUUID}
            errorCode="veteran_not_valid"
            errorData={veteranInvalidFields} />
      }

      <BenefitType
        value={benefitType}
        onChange={this.props.setBenefitType}
        errorMessage={benefitTypeError || errors?.['benefit-type-options']?.message}
        register={this.props.register}
      />

      <ReceiptDateInput
        {...this.props}
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
  informalConference: PropTypes.string,
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
  supplementalClaimStatus: PropTypes.string,
  errorUUID: PropTypes.string,
  register: PropTypes.func,
  errors: PropTypes.array
};

const SelectClaimantConnected = connect(
  ({ supplementalClaim, intake, featureToggles }) => ({
    isVeteranDeceased: intake.veteran.isDeceased,
    veteranIsNotClaimant: supplementalClaim.veteranIsNotClaimant,
    veteranIsNotClaimantError: supplementalClaim.veteranIsNotClaimantError,
    claimant: supplementalClaim.claimant,
    claimantError: supplementalClaim.claimantError,
    payeeCode: supplementalClaim.payeeCode,
    payeeCodeError: supplementalClaim.payeeCodeError,
    relationships: supplementalClaim.relationships,
    benefitType: supplementalClaim.benefitType,
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
    supplementalClaimStatus: getIntakeStatus(state),
    receiptDate: state.supplementalClaim.receiptDate,
    receiptDateError: state.supplementalClaim.receiptDateError,
    benefitType: state.supplementalClaim.benefitType,
    benefitTypeError: state.supplementalClaim.benefitTypeError,
    legacyOptInApproved: state.supplementalClaim.legacyOptInApproved,
    legacyOptInApprovedError: state.supplementalClaim.legacyOptInApprovedError,
    reviewIntakeError: state.supplementalClaim.requestStatus.reviewIntakeError,
    errorUUID: state.supplementalClaim.requestStatus.errorUUID,
    veteranValid: state.supplementalClaim.veteranValid,
    veteranInvalidFields: state.supplementalClaim.veteranInvalidFields
  }),
  (dispatch) => bindActionCreators({
    setReceiptDate,
    setBenefitType,
    setLegacyOptInApproved
  }, dispatch)
)(Review);

export { reviewSupplementalClaimSchema };
