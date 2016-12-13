import React, { PropTypes } from 'react';
export default class TextareaField extends React.Component {
  render() {
    let {
      characterCount,
      errorMessage,
      label,
      name,
      onChange,
      required,
      type,
      value
    } = this.props;

    let className = `cf-form-textarea cf-form-textarea--full-width` +
          `${errorMessage ? " usa-input-error" : ""}`;

    return <div className={className}>
      <label className="question-label" htmlFor={name}>
        {label || name} {required && <span className="cf-required">(Required)</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <textarea
        className="cf-form-textarea"
        name={name}
        id={name}
        onChange={onChange}
        type={type}
        value={value}
      />
      {characterCount &&
        <p>Character Count: {value.length}</p>
      }
    </div>;
  }
}

TextareaField.propTypes = {
  characterCount: PropTypes.bool,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.string
};

