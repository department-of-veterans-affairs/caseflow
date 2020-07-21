import React from 'react';
import PropTypes from 'prop-types';
import classNamesFn from 'classnames';
import pluralize from 'pluralize';

import { FormLabel } from './FormLabel';

/**
 * A text area allows multiple lines of text so that users can enter detailed and descriptive requested information.
 * This freeform field allows users to write as much as they need to.
 * When the message is longer than the length of the box, a scroll bar will appear on the side.
 */
export default class TextareaField extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  };

  render() {
    const {
      errorMessage,
      hideLabel,
      id,
      maxlength,
      label,
      strongLabel,
      name,
      required,
      type,
      value,
      styling,
      textAreaStyling,
      disabled,
      labelStyling,
      placeholder,
      optional,
    } = this.props;

    const className = classNamesFn('cf-form-textarea', {
      'usa-input-error': Boolean(errorMessage),
    });

    // There is only a value for this variable if maxlength and value props are not null.
    // Otherwise characterLimitCount will be null also.
    const characterLimitCount =
      Boolean(maxlength) && Boolean(value) ? maxlength - value.length : null;

    const labelContents = (
      <FormLabel
        label={label}
        name={name}
        required={required}
        optional={optional}
      />
    );

    // hideLabel still leaves the label element in the DOM (for a11y purposes)
    // but makes it invisible to any screens
    return (
      <div className={className} {...styling}>
        <label
          {...labelStyling}
          className={classNamesFn({ 'sr-only': hideLabel }, 'question-label')}
          htmlFor={id || name}
        >
          {strongLabel ? <strong>{labelContents}</strong> : labelContents}
        </label>
        {errorMessage && (
          <span className="usa-input-error-message">{errorMessage}</span>
        )}
        <textarea
          {...textAreaStyling}
          name={name}
          id={id || name}
          onChange={this.onChange}
          onKeyDown={this.props.onKeyDown}
          type={type}
          value={value}
          maxLength={maxlength}
          disabled={disabled}
          placeholder={placeholder}
        />
        {characterLimitCount !== null && (
          <p>
            <i>
              {characterLimitCount}{' '}
              {pluralize('character', characterLimitCount)} left
            </i>
          </p>
        )}
      </div>
    );
  }
}

TextareaField.defaultProps = {
  disabled: false,
  optional: false,
  required: false,
};

TextareaField.propTypes = {
  hideLabel: PropTypes.bool,
  id: PropTypes.string,
  label: PropTypes.string,
  strongLabel: PropTypes.bool,
  maxlength: PropTypes.number,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  onKeyDown: PropTypes.func,
  type: PropTypes.string,
  errorMessage: PropTypes.string,
  value: PropTypes.string,
  styling: PropTypes.object,
  disabled: PropTypes.bool,
  placeholder: PropTypes.string,
  optional: PropTypes.bool,
  required: PropTypes.bool,
  labelStyling: PropTypes.object,
  textAreaStyling: PropTypes.object,
};
