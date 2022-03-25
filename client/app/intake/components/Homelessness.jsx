import React from 'react';
import RadioField from '../../components/RadioField';
import { INTAKE_HOMELESSNESS_MESSAGE } from '../../../COPY';
import { convertStringToBoolean } from '../util';
import PropTypes from 'prop-types';

//const RadioOptions
const radioOptions = [
  { value: 'false',
    displayText: 'No' },
  { value: 'true',
    displayText: 'Yes' }
];

export default class Homelessness extends React.PureComponent {
  render = () => {
    const {
      value,
      errorMessage,
      onChange,
      register
    } = this.props;

    return <div className="cf-homelessness" style={{ marginTop: '10px' }}>
      <RadioField
        name="homelessness"
        label={<span><b>Did the claimant check the "I am experiencing homelessness" box on the form?</b></span>} 
        vertical
        options={radioOptions}
        onChange={(newValue) => {
          onChange(convertStringToBoolean(newValue));
        }}
        errorMessage={errorMessage} // Add error handling
        value={value === null ? null : value?.toString()}
        inputRef={register}
        optional
      />
    </div>;
  }
}


Homelessness.propTypes = {
  errorMessage: PropTypes.string,
  onChange: PropTypes.func,
  value: PropTypes.bool,
  register: PropTypes.func
};

