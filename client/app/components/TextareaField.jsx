import React, { PropTypes } from 'react';

export default class TextareaField extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  render() {
    let {
      characterCount,
      characterLimit,
      errorMessage,
      id,
      label,
      name,
      required,
      type,
      value
    } = this.props;

    let className = 'cf-form-textarea' +
          `${errorMessage ? ' usa-input-error' : ''}`;

    let characterLimitCount = 2000 - value.length;

    return <div className={className}>
      <label className="question-label" htmlFor={name}>
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
      />
      {characterCount &&
        <p>Character Count: {value.length}</p>
      }
      {characterLimit &&
        <i>{characterLimitCount} characters left</i>
      }
    </div>;
  }
}

TextareaField.propTypes = {
  characterCount: PropTypes.bool,
  id: PropTypes.string,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  onKeyDown: PropTypes.func,
  type: PropTypes.string,
  errorMessage: PropTypes.string,
  value: PropTypes.string
};
