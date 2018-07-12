import React from 'react';
import PropTypes from 'prop-types';
import classNamesFn from 'classnames';
import pluralize from 'pluralize';

export default class TextareaField extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  render() {
    const {
      errorMessage,
      hideLabel,
      id,
      maxlength,
      label,
      name,
      required,
      type,
      value,
      styling
    } = this.props;

    const className = 'cf-form-textarea' +
          `${errorMessage ? ' usa-input-error' : ''}`;

    // There is only a value for this variable if maxlength and value props are not null.
    // Otherwise characterLimitCount will be null also.
    const characterLimitCount = (Boolean(maxlength) && Boolean(value)) ? (maxlength - value.length) : null;

    // hideLabel still leaves the label element in the DOM (for a11y purposes)
    // but makes it invisible to any screens
    return <div className={className} {...styling}>
      <label className={classNamesFn({ 'sr-only': hideLabel }, 'question-label')} htmlFor={id || name}>
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
      { characterLimitCount !== null && <p>
        <i>{characterLimitCount} {pluralize('character', characterLimitCount)} left</i>
      </p> }
    </div>;
  }
}

TextareaField.propTypes = {
  hideLabel: PropTypes.bool,
  id: PropTypes.string,
  label: PropTypes.string,
  maxlength: PropTypes.number,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  onKeyDown: PropTypes.func,
  type: PropTypes.string,
  errorMessage: PropTypes.string,
  value: PropTypes.string,
  styling: PropTypes.object
};
