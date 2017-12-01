import React from 'react';
import RadioField from '../../components/RadioField';
import DateSelector from '../../components/DateSelector';
import Button from '../../components/Button';

export default class Review extends React.PureComponent {
  onElectionChange = () => {
    // eslint-disable-next-line no-console
    console.log('not yet implemented');
  }

  render() {
    const radioOptions = [
      { displayText: 'Supplemental Claim' },
      { displayElem: <span>Higher Level Review <strong>with</strong> DRO hearing request</span> },
      { displayElem: <span>Higher Level Review with<strong>out</strong> DRO hearing request</span> },
      { displayText: 'Withdraw all pending appeals' }
    ];

    return <div>
      <h1>Review Joe Snuffy's opt-in request</h1>
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
