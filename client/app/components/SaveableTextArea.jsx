import React from 'react';
import PropTypes from 'prop-types';

import Button from './Button';
import TextareaField from './TextareaField';

export default class SaveableTextArea extends React.PureComponent {
  render() {
    const {
      disabled,
      hideLabel,
      id,
      name,
      onChange,
      onCancelClick,
      onKeyDown,
      onSaveClick,
      value
    } = this.props;

    return <div className="comment-size-container">
      <TextareaField
        name={name}
        hideLabel={hideLabel}
        aria-label={name}
        onChange={onChange}
        onKeyDown={onKeyDown}
        id={id || name}
        value={value}
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
  }
}

// Both name and onChange are required because of TextareaField
SaveableTextArea.propTypes = {
  disabled: PropTypes.bool,
  id: PropTypes.string,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  onCancelClick: PropTypes.func,
  onKeyDown: PropTypes.func,
  onSaveClick: PropTypes.func,
  value: PropTypes.string
};
