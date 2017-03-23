import React, { PropTypes } from 'react';
import FormField from '../util/FormField';
import BaseForm from '../containers/BaseForm';
import { formatDate } from '../util/DateUtil';
import TextareaField from '../components/TextareaField';

// PdfSidebar shows relevant document information and comments.
// It is intended to be used with the PdfUI component to
// show a PDF with it's corresponding information.
export default class PdfSidebar extends BaseForm {
  constructor(props) {
    super(props);
    this.state = {
      commentForm: {
        addComment: new FormField('')
      }
    };
  }

  onAddCommentComplete = () => {
    let commentForm = { ...this.state.commentForm };

    commentForm.addComment.value = '';
    this.setState({
      commentForm
    });
    this.props.onAddCommentComplete();
  }

  // We use keyDown to capture enter and escape events.
  addCommentKeyDown = (event) => {
    if (event.key === 'Enter') {
      if (this.state.commentForm.addComment.value.length > 0) {
        this.props.onSaveComment(this.state.commentForm.addComment.value);
      }
      this.onAddCommentComplete();
      event.preventDefault();
    } else if (event.key === 'Escape') {
      this.resetCommentForm();
      event.onAddCommentComplete();
    }
  }

  render() {
    return <div className="cf-sidebar-wrapper">
        <div className="cf-document-info-wrapper">
          <div className="cf-heading-alt">Document</div>
          <p className="cf-pdf-meta-title">
            <b>Filename:</b> {this.props.doc.filename}
          </p>
          <p className="cf-pdf-meta-title">
            <b>Document Type:</b> {this.props.doc.type}
          </p>
          <p className="cf-pdf-meta-title">
            <b>Receipt Date:</b> {formatDate(this.props.doc.receivedAt)}
          </p>
          <div className="cf-heading-alt">
            Comments
            <span className="cf-right-side">
              <a onClick={this.props.onAddComment}>+ Add a Comment</a>
            </span>
          </div>
        </div>

        <div className="cf-comment-wrapper">
          <div className="cf-pdf-comment-list">
            <div
              className="cf-pdf-comment-list-item"
              hidden={!this.props.isAddingComment}>
              <TextareaField
                label="Add Comment"
                name="addComment"
                onChange={this.handleFieldChange('commentForm', 'addComment')}
                onKeyDown={this.addCommentKeyDown}
                {...this.state.commentForm.addComment}
              />
            </div>
            {this.props.comments}
          </div>
        </div>
      </div>;
  }
}

PdfSidebar.propTypes = {
  onAddComment: PropTypes.func,
  doc: PropTypes.object,
  comments: PropTypes.node,
  isAddingComment: PropTypes.bool,
  onSaveComment: PropTypes.func,
  onAddCommentComplete: PropTypes.func
};
