import React, { PropTypes } from 'react';
import { formatDate } from '../util/DateUtil';
import Comment from '../components/Comment';
import SearchableDropdown from '../components/SearchableDropdown';
import EditComment from '../components/EditComment';

// PdfSidebar shows relevant document information and comments.
// It is intended to be used with the PdfUI component to
// show a PDF with it's corresponding information.
export default class PdfSidebar extends React.Component {

  generateOptionsFromTags = (tags) => {
    if (!tags || tags.length <= 0) {
      return {};
    }
    return tags.map((tag) => {
      return { value: tag.text, label: tag.text }
    });
  };

  render() {
    let comments = [];

    const {
      doc
    } = this.props;

    comments = this.props.comments.map((comment, index) => {
      if (comment.uuid === this.props.editingComment) {
        return <EditComment
            id="editCommentBox"
            onCancelCommentEdit={this.props.onCancelCommentEdit}
            onSaveCommentEdit={this.props.onSaveCommentEdit}
            key={comment.comment}
          >
            {comment.comment}
          </EditComment>;
      }

      return <Comment
        id={`comment${index}`}
        selected={false}
        onDeleteComment={this.props.onDeleteComment}
        onEditComment={this.props.onEditComment}
        uuid={comment.uuid}
        selected={comment.selected}
        onClick={this.props.onJumpToComment}
        key={comment.comment}>
          {comment.comment}
        </Comment>;
    });

    return <div className="cf-sidebar-wrapper">
        <div className="cf-document-info-wrapper">
          <div className="cf-heading-alt">
            Related Issues
          </div>
          <SearchableDropdown 
            name="tags"
            label="Click in the box below to select, type, or add in issue(s)" 
            multi={true}
            creatable={true}
            options={this.generateOptionsFromTags(doc.tags)}
            placeholder="Select or type issue"
            classNames={[]}
          />
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
          <button>Hello</button>
          <div className="cf-heading-alt">
            Comments
            <span className="cf-right-side">
              <a href="#" onClick={this.props.onAddComment}>+ Add a Comment</a>
            </span>
          </div>
        </div>

        <div className="cf-comment-wrapper">
          <div className="cf-pdf-comment-list">
            {this.props.isAddingComment &&
              <EditComment
                id="addComment"
                onCancelCommentEdit={this.props.onCancelCommentAdd}
                onSaveCommentEdit={this.props.onSaveCommentAdd} />}
            {comments}
          </div>
        </div>
      </div>;
  }
}

PdfSidebar.propTypes = {
  onAddComment: PropTypes.func,
  doc: PropTypes.object,
  comments: React.PropTypes.arrayOf(React.PropTypes.shape({
    comment: React.PropTypes.string,
    uuid: React.PropTypes.number
  })),
  editingComment: React.PropTypes.number,
  isAddingComment: PropTypes.bool,
  onSaveCommentAdd: PropTypes.func,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func,
  onCancelCommentAdd: PropTypes.func,
  onDeleteComment: PropTypes.func,
  onJumpToComment: PropTypes.func
};
