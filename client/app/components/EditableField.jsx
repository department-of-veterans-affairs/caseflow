import React, { useState } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import Button from './Button';

/**
 * A field that displays a value that can be edited and saved
 */
export const EditableField = (props) => {
  const {
    className,
    errorMessage,
    inputProps,
    inputRef,
    label,
    maxLength,
    name,
    onCancel,
    onChange,
    onSave,
    placeholder,
    title,
    type,
    value
  } = props;
  const buttonClasses = ['cf-btn-link', 'editable-field-btn-link'];
  let actionLinks, textDisplay;

  // Initialize with the editable field displayed if these is an error
  const [editing, setEditing] = useState(errorMessage && errorMessage.length);

  const startEditing = () => setEditing(true);
  const stopEditing = () => setEditing(false);

  const onSaveClick = () => {
    stopEditing();
    onSave?.(value);
  };

  const saveOnEnter = (event) => {
    if (event.key === 'Enter') {
      onSaveClick();
    }
  };

  const onCancelClick = () => {
    stopEditing();
    onCancel?.();
  };

  const onValueChange = (event) => onChange?.(event.target.value);

  if (editing) {
    actionLinks = <span>
      <Button onClick={onCancelClick} id={`${name}-cancel`} classNames={buttonClasses}>
        Cancel
      </Button>&nbsp;|&nbsp;
      <Button onClick={onSaveClick} id={`${name}-save`} classNames={buttonClasses}>
        Save
      </Button>
    </span>;
    textDisplay = <input
      ref={inputRef}
      className={className}
      name={name}
      id={name}
      onChange={onValueChange}
      onKeyDown={saveOnEnter}
      type={type}
      value={value}
      placeholder={placeholder}
      title={title}
      maxLength={maxLength}
      {...inputProps}
    />;
  } else {
    actionLinks = <span>
      <Button onClick={startEditing} id={`${name}-edit`} classNames={buttonClasses}>
        Edit
      </Button>
    </span>;
    textDisplay = <span id={name}>{value}</span>;
  }

  return (
    <div className={classNames(className, { 'usa-input-error': errorMessage })}>
      <strong>{label}</strong>
      {actionLinks}<br />
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      {textDisplay}
    </div>
  );
};

EditableField.defaultProps = {
  type: 'text',
  value: ''
};

EditableField.propTypes = {

  /**
   * Class to apply to the wrapping div and input field of the component
   */
  className: PropTypes.string,

  /**
   * Error string to show. Will style entire component as invalid if defined
   */
  errorMessage: PropTypes.string,

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
    PropTypes.shape({ current: PropTypes.instanceOf(Element) }),
  ]),

  /**
   * Text (or other node) to display in associated `label` element
   */
  label: PropTypes.string,

  /**
   * The maximum number of characters allowed in the `input` element. Default value is 524288.
   */
  maxLength: PropTypes.number,

  /**
   * String to be applied to the `name` attribute of the `input` element
   */
  name: PropTypes.string,

  /**
   * Callback fired when the cancel button is clicked
   */
  onCancel: PropTypes.func.isRequired,

  /**
   * Callback fired when value in the text field is changed
   */
  onChange: PropTypes.func,

  /**
   * Callback fired when the cancel button is clicked
   */
  onSave: PropTypes.func.isRequired,

  /**
   * Text to display when `value` is empty
   */
  placeholder: PropTypes.string,

  /**
   * String to be applied to the `title` attribute of the `input` element
   */
  title: PropTypes.string,

  /**
   * String to be applied to the `type` attribute of the `input` element
   */
  type: PropTypes.string,

  /**
   * The value of the `input` element
   */
  value: PropTypes.string
};

export default EditableField;
