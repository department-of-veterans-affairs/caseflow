import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import RadioField from '../../components/RadioField';
import DateSelector from '../../components/DateSelector';
import CancelButton from '../components/CancelButton';
import Button from '../../components/Button';
import { setOptionSelected, setReceiptDate, submitReview } from '../redux/actions';
import { REQUEST_STATE } from '../constants';

class Review extends React.PureComponent {
  render() {
    const radioOptions = [
      {
        value: 'supplemental_claim',
        displayText: 'Supplemental Claim'
      },
      {
        value: 'higher_level_review_with_hearing',
        displayElem: <span>Higher Level Review <strong>with</strong> DRO hearing request</span>
      },
      {
        value: 'higher_level_review',
        displayElem: <span>Higher Level Review with<strong>out</strong> DRO hearing request</span>
      },
      {
        value: 'withdraw',
        displayText: 'Withdraw all pending appeals'
      }
    ];

    return <div>
      <h1>Review { this.props.veteran.name }'s opt-in request</h1>
      <p>Check the Veteran's RAMP Opt-In Election form in the Centralized Portal.</p>

      <RadioField
        name="opt-in-election"
        label="Which election did the Veteran select?"
        strongLabel
        options={radioOptions}
        onChange={this.props.setOptionSelected}
        errorMessage={this.props.rampElection.optionSelectedError}
        value={this.props.rampElection.optionSelected}
      />

      <DateSelector
        name="receipt-date"
        label="What is the Receipt Date for this election form?"
        value={this.props.rampElection.receiptDate}
        onChange={this.props.setReceiptDate}
        errorMessage={this.props.rampElection.receiptDateError}
        strongLabel
      />
    </div>;
  }
}

class ReviewNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.submitReview(this.props.rampElection).then(
      () => this.props.history.push('/finish')
    );
  }

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
  ({ rampElection, requestStatus }) => ({
    requestState: requestStatus.submitReview,
    rampElection
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
  ({ veteran, rampElection }) => ({
    veteran,
    rampElection
  }),
  (dispatch) => bindActionCreators({
    setOptionSelected,
    setReceiptDate
  }, dispatch)
)(Review);
