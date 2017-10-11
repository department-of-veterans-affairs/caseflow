import React from 'react';
import { connect } from 'react-redux';
import RadioField from '../../components/RadioField';
import DateSelector from '../../components/DateSelector';
import Button from '../../components/Button';

class Review extends React.PureComponent {
  onElectionChange = () => {
    // eslint-disable-next-line no-console
    console.log('not yet implemented');
  }

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
        onChange={this.onElectionChange}
      />
      <DateSelector name="receipt-date" label="What is the Receipt Date for this election form?" strongLabel />
    </div>;
  }
}

export class ReviewNextButton extends React.PureComponent {
  handleClick = () => this.props.history.push('/finish')

  render = () => <Button onClick={this.handleClick}>Continue to next step</Button>
}

export default connect(
  ({ veteran }) => ({ veteran })
)(Review);
