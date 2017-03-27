import React, { PropTypes } from 'react';
import FormField from '../util/FormField';
import BaseForm from '../containers/BaseForm';

import Button from '../components/Button';
import TextareaField from '../components/TextareaField';

// A rounded rectangle with a text box for adding
// or editing an existing comment.
export default class EditComment extends BaseForm {
  constructor(props) {
    super(props);
    this.state = {
      commentForm: {
        editComment: new FormField(this.props.children)
      }
    };
  }

  resetForm = () => {
    let commentForm = { ...this.state.commentForm };

    commentForm.editComment.value = '';
    this.setState({
      commentForm
    });
  }

  cancelEdit = () => {
    this.props.onCancelCommentEdit();
    this.resetForm();
  }

  onSaveCommentEdit = () => {
    this.props.onSaveCommentEdit(
      this.state.commentForm.editComment.value, this.props.uuid);
    this.resetForm();
  }

  // If we receive a new 'children' prop, we use it as the text
  // in the edit form.
  componentWillReceiveProps(nextProps) {
    if (nextProps.children !== this.props.children) {
      let commentForm = { ...this.state.commentForm };

      commentForm.editComment.value = nextProps.children;
      this.setState({
        commentForm
      });
    }
  }

  componentDidMount = () => {
    let commentBox = document.getElementById(this.props.id);

    commentBox.focus();
  }

  render() {
    return <div>
        <div
          className="cf-pdf-comment-list-item">
          <TextareaField
            id={this.props.id}
            label="Edit Comment"
            name="editComment"
            onChange={this.handleFieldChange('commentForm', 'editComment')}
            {...this.state.commentForm.editComment}
          />
        </div>
        <div className="comment-control-button-container">
          <span className="cf-right-side">
            <Button
              name="cancel"
              classNames={["cf-btn-link"]}
              onClick={this.cancelEdit}>
              Cancel
            </Button>
            <Button
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
  children: React.PropTypes.string,
  id: React.PropTypes.string,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func
};
