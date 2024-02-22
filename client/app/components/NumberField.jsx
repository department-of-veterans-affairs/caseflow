import React from 'react';
import PropTypes from 'prop-types';
import TextField from './TextField';

export default class NumberField extends React.Component {

  onChange = (value) => {
    let val = value;

    if ((this.props.isInteger && (/\D/).test(val)) || isNaN(value)) {
      val = '';
    }

    this.props.onChange(val && Number(val));
  }

  render() {
    return <div className={this.props.isInteger && 'cf-form-int-input'}>
      <TextField
        {...this.props}
        onChange={this.onChange}
      />
    </div>;
  }
}

NumberField.defaultProps = {
  required: false
};

NumberField.propTypes = {
  errorMessage: PropTypes.string,
  className: PropTypes.arrayOf(PropTypes.string),
  invisible: PropTypes.bool,
  label: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.bool
  ]),
  name: PropTypes.string.isRequired,
  onChange(props) {
    if (!props.readOnly && typeof props.onChange !== 'function') {
      return new Error('If NumberField is not ReadOnly, then onChange must be defined');
    }
  },
  placeholder: PropTypes.string,
  isInteger: PropTypes.bool,
  readOnly: PropTypes.bool,
  required: PropTypes.bool.isRequired,
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number
  ])
};
