import React from 'react';
import RadioField from '../../components/RadioField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';

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
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={onChange}
        errorMessage={errorMessage}
        value={value}
      />
    </div>;
  }
}
