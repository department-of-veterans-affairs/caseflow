import React, { PropTypes } from 'react';
import FormField from '../util/FormField';
import BaseForm from '../containers/BaseForm';

import Button from '../components/Button';
import TextareaField from '../components/TextareaField';

// A rounded rectangle with a user's comment inside
export default class Comment extends BaseForm {
  constructor(props) {
    super(props);
    this.state = {
      commentForm: {
        editComment: new FormField('')
      },
      commentOverIndex: null,
      editingComment: false
    };
  }

  editComment = () => {
    let commentForm = { ...this.state.commentForm };

    commentForm.editComment.value = this.props.children;
    this.setState({
      commentForm,
      editingComment: true
    });
  }

  cancelEdit = () => {
    let commentForm = { ...this.state.commentForm };

    commentForm.editComment.value = '';
    this.setState({
      commentForm,
      editingComment: false
    });
  }

  onSaveCommentEdit = () => {
    this.props.onSaveCommentEdit(this.state.commentForm.editComment.value, this.props.uuid);
    this.cancelEdit();
  }

  onDeleteComment = () => {
    this.props.onDeleteComment(this.props.uuid);
  }

  render() {
    let className = 'cf-pdf-comment-list-item';
    if (this.props.selected) {
      className = className + ' cf-comment-selected';
    }

    let comment;

    if (this.state.editingComment) {
      comment = <div>
          <div
            key={this.props.children.toString()}
            className="cf-pdf-comment-list-item">
            <TextareaField
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
    } else {
      //onClick={this.scrollToAnnotation(comment.uuid)}
      comment = <div>
          <div className="comment-control-button-container">
            <span className="cf-right-side">
              <Button
                name="edit"
                classNames={["cf-btn-link comment-control-button"]}
                onClick={this.editComment}>
                Edit
              </Button>
              <span className="comment-control-button-divider">
                |
              </span>
              <Button
                name="delete"
                classNames={["cf-btn-link comment-control-button"]}
                onClick={this.onDeleteComment}>
                Delete
              </Button>
            </span>
          </div>
          <div
            className={className}
            key={this.props.children.toString()}
            id={this.props.id}>
            {this.props.children}
          </div>
        </div>;
    }

    return comment;
  }
}

Comment.propTypes = {
  children: React.PropTypes.string,
  id: PropTypes.string,
  selected: PropTypes.bool,
  onSaveCommentEdit: PropTypes.func,
  onDeleteComment: PropTypes.func,
  uuid: PropTypes.number
};
