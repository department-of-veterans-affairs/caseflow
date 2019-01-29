import React from 'react';
import RadioField from '../../components/RadioField';

const radioOptions = [
  { value: 'false',
    displayText: 'N/A' },
  { value: 'true',
    displayText: 'Yes' }
];

export default class LegacyOptInApproved extends React.PureComponent {
  render = () => {
    const {
      value,
      errorMessage,
      onChange
    } = this.props;

    return <div className="cf-legacy-opt-in">
      <RadioField
        name="legacy-opt-in"
        label="Did they agree to withdraw their issues from the legacy system?"
        strongLabel
        vertical
        options={radioOptions}
        onChange={onChange}
        errorMessage={errorMessage}
        value={value}
      />
    </div>;
  }
}
