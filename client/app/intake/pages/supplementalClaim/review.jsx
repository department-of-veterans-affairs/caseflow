import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import DateSelector from '../../../components/DateSelector';
import CancelButton from '../../components/CancelButton';
import { Redirect } from 'react-router-dom';
import Button from '../../../components/Button';
import BenefitType from '../../components/BenefitType';
import LegacyOptInApproved from '../../components/LegacyOptInApproved';
import SelectClaimant from '../../components/SelectClaimant';
import {
  submitReview,
  setBenefitType,
  setClaimantNotVeteran,
  setClaimant,
  setPayeeCode,
  setLegacyOptInApproved
} from '../../actions/ama';
import { setReceiptDate } from '../../actions/intake';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES, REQUEST_STATE } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';

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
      reviewIntakeError
    } = this.props;

    switch (supplementalClaimStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    return <div>
      <h1>Review { veteranName }'s { FORM_TYPES.SUPPLEMENTAL_CLAIM.name }</h1>

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

      <SelectClaimantConnected />

      <LegacyOptInApproved
        value={legacyOptInApproved === null ? null : legacyOptInApproved.toString()}
        onChange={this.props.setLegacyOptInApproved}
        errorMessage={legacyOptInApprovedError}
      />
    </div>;
  }
}

const SelectClaimantConnected = connect(
  ({ supplementalClaim }) => ({
    claimantNotVeteran: supplementalClaim.claimantNotVeteran,
    claimant: supplementalClaim.claimant,
    payeeCode: supplementalClaim.payeeCode,
    relationships: supplementalClaim.relationships
  }),
  (dispatch) => bindActionCreators({
    setClaimantNotVeteran,
    setClaimant,
    setPayeeCode
  }, dispatch)
)(SelectClaimant);

class ReviewNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.submitReview(this.props.intakeId, this.props.supplementalClaim, 'supplementalClaim').then(
      () => this.props.history.push('/finish')
    );
  };

  render = () =>
    <Button
      name="submit-review"
      onClick={this.handleClick}
      loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}
    >
      Continue to next step
    </Button>;
}

const ReviewNextButtonConnected = connect(
  ({ supplementalClaim, intake }) => ({
    intakeId: intake.id,
    requestState: supplementalClaim.requestStatus.submitReview,
    supplementalClaim
  }),
  (dispatch) => bindActionCreators({
    submitReview
  }, dispatch)
)(ReviewNextButton);

export class ReviewButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <ReviewNextButtonConnected history={this.props.history} />
    </div>
}

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
    reviewIntakeError: state.supplementalClaim.requestStatus.reviewIntakeError
  }),
  (dispatch) => bindActionCreators({
    setReceiptDate,
    setBenefitType,
    setLegacyOptInApproved
  }, dispatch)
)(Review);
