import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import DateSelector from '../../../components/DateSelector';
import CancelButton from '../../components/CancelButton';
import { Redirect } from 'react-router-dom';
import Button from '../../../components/Button';
import SelectClaimant from '../../components/SelectClaimant';
import { submitReview, setClaimantNotVeteran, setClaimant, setPayeeCode } from '../../actions/ama';
import { setReceiptDate } from '../../actions/common';
import { REQUEST_STATE, PAGE_PATHS, INTAKE_STATES } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';

class Review extends React.PureComponent {
  render() {
    const {
      supplementalClaimStatus,
      veteranName,
      receiptDate,
      receiptDateError,
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
      <h1>Review { veteranName }'s Supplemental Claim (VA Form 21-526b)</h1>

      { reviewIntakeError && <ErrorAlert /> }

      <DateSelector
        name="receipt-date"
        label="What is the Receipt Date of this form?"
        value={receiptDate}
        onChange={this.props.setReceiptDate}
        errorMessage={receiptDateError}
        strongLabel
      />

      <SelectClaimantConnected />

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
      legacyStyling={false}
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
    reviewIntakeError: state.supplementalClaim.requestStatus.reviewIntakeError
  }),
  (dispatch) => bindActionCreators({
    setReceiptDate
  }, dispatch)
)(Review);
