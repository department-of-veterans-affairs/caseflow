import React, { PropTypes } from 'react';
import Button from '../components/Button';

// A rounded rectangle with a text box for adding
// or editing an existing comment.
export default class EditComment extends React.Component {
  componentDidMount = () => {
    let commentBox = document.getElementById(this.props.id);

    commentBox.focus();
  }

  render() {
    return <div>
        <textarea
          className="comment-container comment-textarea"
          name="Edit Comment"
          aria-label="Edit Comment"
          id={this.props.id}
          onChange={(event) => this.props.onChange(event.target.value)}
          value={this.props.value}
        />
        <div className="comment-save-button-container">
          <span className="cf-right-side">
            <Button
              name="cancel"
              classNames={['cf-btn-link']}
              onClick={this.props.onCancelCommentEdit}>
              Cancel
            </Button>
            <Button
              name="save"
              onClick={this.props.onSaveCommentEdit}>
              Save
            </Button>
          </span>
        </div>
      </div>;
  }
}

EditComment.defaultProps = {
  id: 'commentEditBox'
};

EditComment.propTypes = {
  value: React.PropTypes.string,
  id: React.PropTypes.string,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func
};
