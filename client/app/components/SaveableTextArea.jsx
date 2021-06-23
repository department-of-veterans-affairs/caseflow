import React from 'react';
import PropTypes from 'prop-types';

import Button from './Button';
import TextareaField from './TextareaField';

/**
 * A long text field with accompanying save and cancel buttons. Props 'name' and 'onChange' are required
 */
export const SaveableTextArea = (props) => {
  const { disabled, id, name, onCancelClick, onSaveClick, ...textAreaProps } = props;

  return <div className="comment-size-container">
    <TextareaField
      name={name}
      aria-label={name}
      id={id || name}
      {...textAreaProps}
    />
    <div className="comment-save-button-container">
      <span className="cf-right-side">
        <Button
          name="cancel"
          classNames={['cf-btn-link']}
          onClick={onCancelClick}>
            Cancel
        </Button>
        <Button
          disabled={disabled}
          name="save"
          onClick={onSaveClick}>
            Save
        </Button>
      </span>
    </div>
  </div>;
};

SaveableTextArea.propTypes = {

  /**
   * Whether or not the save button is disabled
   */
  disabled: PropTypes.bool,

  /**
   * Whether or not to show the label above the text field
   */
  hideLabel: PropTypes.bool,

  /**
   * Sets the `id` attribute on the `input` element; defaults to value of `name` prop
   */
  id: PropTypes.string,

  /**
   * Text (or other node) to display in associated `label` element
   */
  label: PropTypes.string,

  /**
   * String to be applied to the `name` attribute of the `input` element. Required
   */
  name: PropTypes.string.isRequired,

  /**
   * Callback fired when the cancel button is clicked
   */
  onCancelClick: PropTypes.func,

  /**
   * Callback fired when value in the text field is changed
   */
  onChange: PropTypes.func.isRequired,

  /**
   * Callback fired when a key is pressed while the text field is in focus
   */
  onKeyDown: PropTypes.func,

  /**
   * Callback to perform when the save button is clicked
   */
  onSaveClick: PropTypes.func,

  /**
   * Value of the `input` element
   */
  value: PropTypes.string
};

export default SaveableTextArea;
