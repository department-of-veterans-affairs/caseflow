import React, { PropTypes } from 'react';
export default class DateSelector extends React.Component {
  render() {
    let {
      label,
      name,
      onChange,
      readOnly,
      type,
      value,
      validationError
    } = this.props;

    return (<div className="cf-form-textinput">
      <label className="question-label" htmlFor={name}>{label || name}</label>
      <input
        className="cf-form-textinput"
        name={name}
        onChange={onChange}
        type={type}
        value={value}
        readOnly={readOnly}
      />
      <div className="cf-validation">
        <span>{validationError}</span>
      </div>
    </div>);
  }
}

DateSelector.defaultProps = {
  type: 'text'
}

