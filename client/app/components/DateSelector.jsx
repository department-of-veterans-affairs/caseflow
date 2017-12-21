import React from 'react';
import PropTypes from 'prop-types';
import TextField from '../components/TextField';
import _ from 'lodash';

const DEFAULT_TEXT = 'mm/dd/yyyy';
const MIN_DATE = `${new Date().getFullYear()}-01-01`;

export default class DateSelector extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      errorMessage: undefined,
      minDate: this.props.minDate || MIN_DATE
    };

    if (_.isDate(this.props.minDate)) {
      const minDate = this.props.minDate;
      this.state.minDate = `${minDate.getFullYear()}-${minDate.getMonth()}-${minDate.getDay()}`;
    }
  }

  onChange = (value) => {
    // if date is invalid (e.g. 02/31/2017), input type=date returns '', and
    // won't fire onChange again until valid date supplied
    if (!value || new Date(value) < new Date(this.props.min || MIN_DATE)) {
      this.setState({ errorMessage: this.props.errorMessage });
    } else {
      this.setState({ errorMessage: undefined });
    }

    this.props.onChange(value);
  }

  render() {
    let {
      label,
      name,
      readOnly,
      required,
      validationError,
      value,
      ...passthroughProps
    } = _.omit(this.props, 'onChange', 'errorMessage');

    return <TextField
      className={['comment-relevant-date cf-form-textinput']}
      errorMessage={this.state.errorMessage}
      label={label}
      name={name}
      readOnly={readOnly}
      type="date"
      min={this.state.minDate}
      value={value}
      validationError={validationError}
      onChange={this.onChange}
      placeholder={DEFAULT_TEXT}
      required={required}
      {...passthroughProps}
    />;
  }
}

DateSelector.defaultProps = {
  onChange: _.noop
};

DateSelector.propTypes = {
  errorMessage: PropTypes.string,
  invisible: PropTypes.bool,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  readOnly: PropTypes.bool,
  required: PropTypes.bool,
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.string,
  minDate: PropTypes.oneOfType([
    PropTypes.instanceOf(Date),
    PropTypes.string
  ])
};
