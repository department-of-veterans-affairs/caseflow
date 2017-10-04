import React from 'react';
import PropTypes from 'prop-types';

export default class TextareaField extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  render() {
    let {
      errorMessage,
      id,
      label,
      maxlength,
      name,
      required,
      type,
      value
    } = this.props;

    let className = 'cf-form-textarea' +
          `${errorMessage ? ' usa-input-error' : ''}`;

    let characterLimitCount = maxlength - value.length;



    return <div className={className}>
      <label className="question-label" htmlFor={id || name}>
        {label || name} {required && <span className="cf-required">Required</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <textarea
        name={name}
        id={id || name}
        onChange={this.onChange}
        onKeyDown={this.props.onKeyDown}
        type={type}
        value={value}
        maxLength={maxlength}
      />
      {(characterLimitCount !== maxlength && maxlength) &&
        <p><i>{characterLimitCount} characters left</i></p>
      }
    </div>;
  }
}

TextareaField.propTypes = {
  id: PropTypes.string,
  label: PropTypes.string,
  maxlength: PropTypes.number,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  onKeyDown: PropTypes.func,
  type: PropTypes.string,
  errorMessage: PropTypes.string,
  value: PropTypes.string
};
