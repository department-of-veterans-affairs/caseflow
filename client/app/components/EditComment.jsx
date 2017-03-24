import React, { PropTypes } from 'react';
import FormField from '../util/FormField';
import BaseForm from '../containers/BaseForm';

import Button from '../components/Button';
import TextareaField from '../components/TextareaField';

// A rounded rectangle with a user's comment inside
export default class EditComment extends BaseForm {
  constructor(props) {
    super(props);
    this.state = {
      commentForm: {
        editComment: new FormField('')
      }
    };
  }

  cancelEdit = () => {
    let commentForm = { ...this.state.commentForm };

    commentForm.editComment.value = '';
    this.setState({
      commentForm
    });
    this.props.onCancelCommentEdit();
  }

  onSaveCommentEdit = () => {
    this.props.onSaveCommentEdit(this.state.commentForm.editComment.value, this.props.uuid);
    this.cancelEdit();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.children !== this.props.children) {
      let commentForm = { ...this.state.commentForm };

      commentForm.editComment.value = nextProps.children;
      this.setState({
        commentForm
      });
    }
  }

  render() {
    let className = 'cf-pdf-comment-list-item';
    if (this.props.selected) {
      className = className + ' cf-comment-selected';
    }
    return <div>
          <div
            key={this.props.children.toString()}
            className={className}>
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
  }
}

Comment.propTypes = {
  children: React.PropTypes.string,
  id: PropTypes.string,
  selected: PropTypes.bool,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func,
  uuid: PropTypes.number
};
