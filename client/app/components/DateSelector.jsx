import React, { PropTypes } from 'react';
import TextField from '../components/TextField';

const DEFAULT_TEXT = 'mm/dd/yyyy';
const DATE_REGEX = /[0,1](?:\d(?:\/(?:[0-3](?:\d(?:\/(?:\d{0,4})?)?)?)?)?)?/;

export default class DateSelector extends React.Component {
  constructor(props) {
    super(props);
    let value = '';
    // TODO (mdbenjam): Add a date formatting package?
    if (props.value) {
      let date = new Date(props.value);  
      value = (date.getMonth()+1) + '/' + date.getDate() + '/' + date.getFullYear();
    }
    this.state = {
      value: value
    };
    this.dateFill = this.dateFill.bind(this);
  }


  dateFill(e) {
    let value = e.target.value;
    if (e.target.value.length > this.state.value.length) {
      value = value + '/'
    } else {
      if (value.charAt(value.length - 1) === '/')
        value = value.substr(0, value.length - 1);
    }

    let match = DATE_REGEX.exec(value);
    
    this.setState({
      value: (match ? match[0] : '')
    });
  }

  render() {
    let {
      label,
      name,
      onChange,
      readOnly,
      type,
      validationError
    } = this.props;

    return (<TextField 
      label={label}
      name={name}
      readOnly={readOnly}
      type={type}
      value={this.state.value}
      validationError={validationError}
      onChange={this.dateFill}
      placeholder={DEFAULT_TEXT}
      />);
  }
}

TextField.propTypes = {
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.string,
  readOnly: PropTypes.bool,
  invisible: PropTypes.bool
};