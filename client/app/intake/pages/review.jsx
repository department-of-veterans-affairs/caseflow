import React from 'react';
import RadioField from '../../components/RadioField';

export default class Review extends React.PureComponent {
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
        label={<h3>Which election did the Veteran select?</h3>}
        options={radioOptions}
      />
    </div>;
  }
}


