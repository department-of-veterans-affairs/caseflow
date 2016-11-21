import React, { PropTypes } from 'react';
export default class TextField extends React.Component {
  render() {
    let {
      label,
      name,
      onChange,
      type,
      value,
      validationError
    } = this.props;

    return (<div className="cf-form-textinput">
      <label className="question-label" htmlFor={name}>{label || name}</label>
      <input
        className="cf-form-textinput"
        name={name}
        id={name}
        onChange={onChange}
        type={type}
        value={value}
      />
      <div className="cf-validation">
        <span>{validationError}</span>
      </div>
    </div>);
  }
}

TextField.defaultProps = {
  type: 'text'
};

TextField.propTypes = {
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.string
};
