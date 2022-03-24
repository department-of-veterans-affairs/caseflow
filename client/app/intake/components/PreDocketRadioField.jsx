import React from 'react';
import RadioField from '../../components/RadioField';
import { convertStringToBoolean } from '../util';
import PropTypes from 'prop-types';

const radioOptions = [
  {
    value: true,
    displayText: 'Yes'
  },
  {
    value: false,
    displayText: 'No'
  }
];

export default class PreDocketRadioField extends React.PureComponent {
  render = () => {
    const {
      value,
      onChange,
      register
    } = this.props;

    return <div className="cf-is-predocket" style={{ height: '4em', marginTop: '10px' }}>
      <RadioField
        name="pre-docket"
        label={<span><b>Is pre-docketing needed for this issue?</b></span>}
        options={radioOptions}
        onChange={(newValue) => {
          onChange(convertStringToBoolean(newValue));
        }}
        value={value}
        inputRef={register}
      />
    </div>;
  }
}

PreDocketRadioField.propTypes = {
  onChange: PropTypes.func,
  value: PropTypes.bool,
  register: PropTypes.func
};
