import React, { PropTypes } from 'react';
export default class TextField extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  render() {
    let {
      errorMessage,
      label,
      name,
      readOnly,
      required,
      type,
      value,
      validationError,
      invisible,
      placeholder
    } = this.props;

    return <div className={`cf-form-textinput${invisible ? " cf-invisible" : ""}`}>
      <label className="question-label" htmlFor={name}>
        {label || name} {required && <span className="cf-required">Required</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <input
        className="cf-form-textinput"
        name={name}
        id={name}
        onChange={this.onChange}
        type={type}
        value={value}
        readOnly={readOnly}
        placeholder={placeholder}
      />
      <div className="cf-validation">
        <span>{validationError}</span>
      </div>
    </div>;
  }
}

TextField.defaultProps = {
  required: false,
  type: 'text'
};

TextField.propTypes = {
  errorMessage: PropTypes.string,
  invisible: PropTypes.bool,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange(props) {
    if (!props.readOnly) {
      if (typeof props.onChange !== 'function') {
        return new Error('If TextField is not ReadOnly, then onChange must be defined');
      }
    }
  },
  placeholder: PropTypes.string,
  readOnly: PropTypes.bool,
  required: PropTypes.bool.isRequired,
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.string
};
