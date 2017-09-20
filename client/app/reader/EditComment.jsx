import React from 'react';
import PropTypes from 'prop-types';

import Button from '../components/Button';

// A rounded rectangle with a text box for adding
// or editing an existing comment.
export default class EditComment extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      isCancelling: false,
      autosaved: false
    };
  }

  componentDidMount = () => {
    let commentBox = document.getElementById(this.props.id);

    commentBox.focus();

    // autosave
    if (!window.onbeforeunload) {
      window.onbeforeunload = () => {
        if (!this.state.autosaved) {
          this.setState({ autosaved: true });
          this.props.onSaveCommentEdit(this.props.comment);
        }
      };
    }
  }

  componentWillUnmount() {
    window.onbeforeunload = null;
    if (!this.state.isCancelling && !this.state.autosaved) {
      this.setState({ autosaved: true });
      this.props.onSaveCommentEdit(this.props.comment);
    }
  }


  onChange = (event) => this.props.onChange(event.target.value, this.props.comment.uuid);

  onCancelCommentEdit = () => {
    this.setState({ isCancelling: true }, this.props.onCancelCommentEdit.bind(this.props.comment.uuid));
  }

  onSaveCommentEdit = () => {
    this.props.onSaveCommentEdit(this.props.comment);
  }

  render() {
    return <div>
        <textarea
          className="comment-container comment-textarea"
          name="Edit Comment"
          aria-label="Edit Comment"
          id={this.props.id}
          onChange={this.onChange}
          value={this.props.comment.comment}
        />
        <div className="comment-save-button-container">
          <span className="cf-right-side">
            <Button
              name="cancel"
              classNames={['cf-btn-link']}
              onClick={this.onCancelCommentEdit}>
              Cancel
            </Button>
            <Button
              disabled={this.props.disableOnEmpty && !this.props.comment.comment}
              name="save"
              onClick={this.onSaveCommentEdit}>
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
  comment: PropTypes.object.isRequired,
  disableOnEmpty: PropTypes.bool,
  id: PropTypes.string,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func
};
