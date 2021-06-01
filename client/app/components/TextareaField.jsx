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
export const TextareaField = (props) => {
  const handleChange = (event) => {
    props?.onChange?.(event.target.value);
  };

  const {
    defaultValue,
    errorMessage,
    hideLabel,
    id,
    inputProps,
    inputRef,
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
    characterLimitTopRight,
  } = props;

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

  const characterLimitContent = (
    <p style={characterLimitTopRight ? { float: 'right', marginBottom: 0, lineHeight: 'inherit' } : {}}>
      <i>
        {characterLimitCount} {pluralize('character', characterLimitCount)}{' '}
        left
      </i>
    </p>
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
      {characterLimitCount !== null && characterLimitTopRight && characterLimitContent}
      <textarea
        {...textAreaStyling}
        name={name}
        id={id || name}
        onChange={handleChange}
        onKeyDown={props.onKeyDown}
        type={type}
        defaultValue={defaultValue}
        value={value}
        maxLength={maxlength}
        disabled={disabled}
        placeholder={placeholder}
        ref={inputRef}
        {...inputProps}
      />
      {characterLimitCount !== null && !characterLimitTopRight && characterLimitContent}
    </div>
  );
};

TextareaField.defaultProps = {
  disabled: false,
  optional: false,
  required: false,
  characterLimitTopRight: false
};

TextareaField.propTypes = {

  /**
   * The initial value of the `input` element; use for uncontrolled components where not using `value` prop
   */
  defaultValue: PropTypes.string,

  hideLabel: PropTypes.bool,
  id: PropTypes.string,

  /**
    * Position the character limit in the top-right corner (default: false == position bottom left)
    */
  characterLimitTopRight: PropTypes.bool,

  /**
   * Props to be applied to the `input` element
   */
  inputProps: PropTypes.object,

  /**
   * Pass a ref to the `input` element
   */
  inputRef: PropTypes.oneOfType([
    // Either a function
    PropTypes.func,
    // Or the instance of a DOM native element (see the note about SSR)
    PropTypes.shape({ current: PropTypes.instanceOf(Element) })
  ]),

  label: PropTypes.oneOfType([PropTypes.string, PropTypes.node]),
  strongLabel: PropTypes.bool,
  maxlength: PropTypes.number,

  /**
   * String to be applied to the `name` attribute of the `input` element
   */
  name: PropTypes.string.isRequired,

  /**
   * Callback fired when value is changed
   *
   * @param {string} value The current value of the component
   */
  onChange: PropTypes.func,

  onKeyDown: PropTypes.func,
  type: PropTypes.string,
  errorMessage: PropTypes.string,
  styling: PropTypes.object,
  disabled: PropTypes.bool,
  placeholder: PropTypes.string,
  optional: PropTypes.bool,
  required: PropTypes.bool,
  labelStyling: PropTypes.object,
  textAreaStyling: PropTypes.object,

  /**
   * The value of the `input` element; required for a controlled component
   */
  value: PropTypes.string,
};

export default TextareaField;
