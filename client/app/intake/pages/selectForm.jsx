import React from 'react';
import RadioField from '../../components/RadioField';

export default class SelectForm extends React.PureComponent {
  render() {
    const radioOptions = [
      {
        value: 'ramp_opt_in_election',
        displayText: 'RAMP Opt-In Election Form'
      },
      {
        value: 'ramp_reentry_selection',
        displayText: '21-4138 RAMP Selection Form'
      }
    ];

    return <div>
      <h1>Welcome to Caseflow Intake!</h1>
      <p>Please select the form you are processing from the Centralized Mail Portal.</p>

      <RadioField
        name="form-select"
        label="Which form are you processing?"
        vertical
        strongLabel
        options={radioOptions}
      />
    </div>;
  }
}
