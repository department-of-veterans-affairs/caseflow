import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import * as yup from 'yup';
import DateSelector from '../../../components/DateSelector';
import { Redirect } from 'react-router-dom';
import BenefitType from '../../components/BenefitType';
import LegacyOptInApproved from '../../components/LegacyOptInApproved';
import SelectClaimant from '../../components/SelectClaimant';
import {
  setBenefitType,
  setVeteranIsNotClaimant,
  setClaimant,
  setPayeeCode,
  setLegacyOptInApproved
} from '../../actions/decisionReview';
import { setReceiptDate } from '../../actions/intake';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES, VBMS_BENEFIT_TYPES, CLAIMANT_ERRORS } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';
import PropTypes from 'prop-types';

const reviewSupplementalClaimSchema = yup.object().shape({
  'benefit-type-options': yup.string().required(CLAIMANT_ERRORS.blank),
  'receipt-date': yup.date().required(),
  'different-claimant-option': yup.string().required(CLAIMANT_ERRORS.blank),
  'legacy-opt-in': yup.string().required(CLAIMANT_ERRORS.blank),
  'claimant-options': yup.string().notRequired().when('different-claimant-option', {
    is: "true",
    then: yup.string().required(CLAIMANT_ERRORS.blank)
  })
});

class Review extends React.PureComponent {
  render() {
    const {
      supplementalClaimStatus,
      veteranName,
      receiptDate,
      receiptDateError,
      benefitType,
      benefitTypeError,
      legacyOptInApproved,
      legacyOptInApprovedError,
      reviewIntakeError,
      veteranValid,
      veteranInvalidFields
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
        errorMessage={this.props.errors['benefit-type-options'] && this.props.errors['benefit-type-options'].message}
        register={this.props.register}
      />

      <DateSelector
        name="receipt-date"
        label="What is the Receipt Date of this form?"
        value={receiptDate}
        onChange={this.props.setReceiptDate}
        errorMessage={this.props.errors['receipt-date'] && this.props.errors['receipt-date'].message}
        type="date"
        strongLabel
        inputRef={this.props.register}
      />

      <SelectClaimantConnected 
        register={this.props.register} 
        errors={this.props.errors} 
      />

      <LegacyOptInApproved
        value={legacyOptInApproved}
        onChange={this.props.setLegacyOptInApproved}
        errorMessage={this.props.errors['legacy-opt-in'] && this.props.errors['legacy-opt-in'].message}
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
  errorUUID: PropTypes.string
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

export {reviewSupplementalClaimSchema}