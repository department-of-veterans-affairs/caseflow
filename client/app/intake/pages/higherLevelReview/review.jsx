import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';
import RadioField from '../../../components/RadioField';
import DateSelector from '../../../components/DateSelector';
import BenefitType from '../../components/BenefitType';
import LegacyOptInApproved from '../../components/LegacyOptInApproved';
import SelectClaimant from '../../components/SelectClaimant';
import { setInformalConference, setSameOffice } from '../../actions/higherLevelReview';
import {
  setBenefitType,
  setVeteranIsNotClaimant,
  setClaimant,
  setPayeeCode,
  setLegacyOptInApproved
} from '../../actions/decisionReview';
import { setReceiptDate } from '../../actions/intake';
import { PAGE_PATHS, INTAKE_STATES, BOOLEAN_RADIO_OPTIONS, FORM_TYPES } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';

class Review extends React.PureComponent {
  render() {
    const {
      higherLevelReviewStatus,
      veteranName,
      receiptDate,
      receiptDateError,
      benefitType,
      benefitTypeError,
      informalConference,
      informalConferenceError,
      sameOffice,
      sameOfficeError,
      legacyOptInApproved,
      legacyOptInApprovedError,
      reviewIntakeError,
      featureToggles
    } = this.props;

    switch (higherLevelReviewStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    const legacyOptInEnabled = featureToggles.legacyOptInEnabled;

    return <div>
      <h1>Review { veteranName }'s { FORM_TYPES.HIGHER_LEVEL_REVIEW.name }</h1>

      { reviewIntakeError && <ErrorAlert /> }

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
        strongLabel
      />

      <RadioField
        name="informal-conference"
        label="Was an informal conference requested?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={this.props.setInformalConference}
        errorMessage={informalConferenceError}
        value={informalConference === null ? null : informalConference.toString()}
      />

      <RadioField
        name="same-office"
        label="Was an interview by the same office requested?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={this.props.setSameOffice}
        errorMessage={sameOfficeError}
        value={sameOffice === null ? null : sameOffice.toString()}
      />

      <SelectClaimantConnected />

      { legacyOptInEnabled && <LegacyOptInApproved
        value={legacyOptInApproved === null ? null : legacyOptInApproved.toString()}
        onChange={this.props.setLegacyOptInApproved}
        errorMessage={legacyOptInApprovedError}
      /> }
    </div>;
  }
}

const SelectClaimantConnected = connect(
  ({ higherLevelReview, intake }) => ({
    isVeteranDeceased: intake.veteran.isDeceased,
    veteranIsNotClaimant: higherLevelReview.veteranIsNotClaimant,
    claimant: higherLevelReview.claimant,
    claimantError: higherLevelReview.claimantError,
    payeeCode: higherLevelReview.payeeCode,
    payeeCodeError: higherLevelReview.payeeCodeError,
    relationships: higherLevelReview.relationships,
    benefitType: higherLevelReview.benefitType,
    formType: intake.formType
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
    reviewIntakeError: state.higherLevelReview.requestStatus.reviewIntakeError
  }),
  (dispatch) => bindActionCreators({
    setInformalConference,
    setSameOffice,
    setReceiptDate,
    setBenefitType,
    setLegacyOptInApproved
  }, dispatch)
)(Review);
