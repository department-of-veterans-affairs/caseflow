import React from 'react';
import PropTypes from 'prop-types';

import Button from './Button';
import classNamesFn from 'classnames';

export default class SaveCommentTextArea extends React.PureComponent {
  render() {
    const {
      disabled,
      id,
      hideLabel,
      name,
      onChange,
      onCancelClick,
      onKeyDown,
      onSaveClick,
      value
    } = this.props;

    return <div className="comment-size-container">
      <label className={classNamesFn({'visuallyhidden': hideLabel})} htmlFor={id || name}>
        {name}
      </label>
      <textarea
        className="comment-container comment-textarea"
        name={name}
        aria-label={name}
        onKeyDown={onKeyDown}
        id={id || name}
        onChange={onChange}
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

SaveCommentTextArea.propTypes = {
  disabled: PropTypes.bool,
  id: PropTypes.string,
  onChange: PropTypes.func,
  onCancelClick: PropTypes.func,
  onKeyDown: PropTypes.func,
  onSaveClick: PropTypes.func,
  value: PropTypes.string
};
