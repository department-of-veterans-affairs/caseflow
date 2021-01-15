import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
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
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES, VBMS_BENEFIT_TYPES } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';
import PropTypes from 'prop-types';

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
        errorMessage={benefitTypeError}
      />

      <DateSelector
        name="receipt-date"
        label="What is the Receipt Date of this form?"
        value={receiptDate}
        onChange={this.props.setReceiptDate}
        errorMessage={receiptDateError}
        type="date"
        strongLabel
      />

      <SelectClaimantConnected />

      <LegacyOptInApproved
        value={legacyOptInApproved === null ? null : legacyOptInApproved}
        onChange={this.props.setLegacyOptInApproved}
        errorMessage={legacyOptInApprovedError}
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
