import React from 'react';
import PropTypes from 'prop-types';

import Button from './Button';

export default class SaveCommentTextArea extends React.PureComponent {
  render() {
    const {
      classNames,
      disabled,
      id,
      onChange,
      onCancelClick,
      onKeyDown,
      onSaveClick,
      value
    } = this.props;

    return <div className="comment-size-container">
      <textarea
        className="comment-container comment-textarea"
        name="Edit Comment"
        aria-label="Edit Comment"
        onKeyDown={onKeyDown}
        id={id}
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
    </div>
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
