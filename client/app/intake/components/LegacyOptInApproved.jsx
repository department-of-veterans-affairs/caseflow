import React from 'react';
import RadioField from '../../components/RadioField';
import { INTAKE_LEGACY_OPT_IN_MESSAGE } from '../../../COPY';
import { convertStringToBoolean } from '../util';
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
      onChange,
      register
    } = this.props;

    return <div className="cf-legacy-opt-in" style={{ marginTop: '10px' }}>
      <RadioField
        name="legacyOptInApproved"
        label={INTAKE_LEGACY_OPT_IN_MESSAGE}
        strongLabel
        vertical
        options={radioOptions}
        onChange={(newValue) => {
          onChange(convertStringToBoolean(newValue));
        }}
        errorMessage={errorMessage}
        value={value === null ? null : value?.toString()}
        inputRef={register}
      />
    </div>;
  }
}

LegacyOptInApproved.propTypes = {
  errorMessage: PropTypes.string,
  onChange: PropTypes.func,
  value: PropTypes.bool,
  register: PropTypes.func
};
