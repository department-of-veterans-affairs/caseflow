import React from 'react';
import RadioField from '../../components/RadioField';
import { INTAKE_LEGACY_OPT_IN_MESSAGE } from '../../../COPY';
import PropTypes from 'prop-types';

const radioOptions = [
  { value: 'false',
    displayText: 'N/A' },
  { value: 'true',
    displayText: 'Yes (SOC/SSOC Opt-in)' }
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
        label={INTAKE_LEGACY_OPT_IN_MESSAGE}
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

LegacyOptInApproved.propTypes = {
  errorMessage: PropTypes.string,
  onChange: PropTypes.func,
  value: PropTypes.string
};
