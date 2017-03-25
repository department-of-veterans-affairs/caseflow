import React, { PropTypes } from 'react';
import FormField from '../util/FormField';
import BaseForm from '../containers/BaseForm';

import Button from '../components/Button';
import TextareaField from '../components/TextareaField';
import EditComment from '../components/EditComment';

// A rounded rectangle with a user's comment inside
export default class Comment extends BaseForm {
  constructor(props) {
    super(props);
    this.state = {
      commentForm: {
        editComment: new FormField('')
      },
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

  onCancelCommentEdit = () => {
    this.setState({
      editingComment: false
    });
  }

  onSaveCommentEdit = () => {
    this.props.onSaveCommentEdit(this.state.commentForm.editComment.value, this.props.uuid);
    this.onCancelCommentEdit();
  }

  onDeleteComment = () => {
    this.props.onDeleteComment(this.props.uuid);
  }

  onClick = () => {
    this.props.onClick(this.props.uuid);
  }

  render() {
    let className = 'cf-pdf-comment-list-item';
    if (this.props.selected) {
      className = className + ' cf-comment-selected';
    }

    let comment;

    if (this.state.editingComment) {
      comment = <EditComment
        onCancelCommentEdit={this.onCancelCommentEdit}
        onSaveCommentEdit={this.onSaveCommentEdit}
        id={this.props.id}
        uuid={this.props.uuid}
        selected={this.props.selected}
      >
        {this.props.children}
      </EditComment>;
    } else {
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
            id={this.props.id}
            onClick={this.onClick}>
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
  onClick: PropTypes.func,
  uuid: PropTypes.number
};
