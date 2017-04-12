import React, { PropTypes } from 'react';
import { formatDate } from '../util/DateUtil';
import Comment from '../components/Comment';
import EditComment from '../components/EditComment';
import _ from 'lodash';
import Checkbox from '../components/Checkbox';
import { connect } from 'react-redux';
import * as Constants from '../reader/constants';

const CategorySelector = (props) => {
  const { category, categoryName, handleCategoryToggle, docId, document } = props;
  const toggleState = _.get(document, [docId, 'categories', categoryName], false);
  const Svg = category.svg;
  const label = <div className="cf-category-selector">
        <Svg />
        <span className="cf-category-name">{category.humanName}</span>
      </div>;

  const handleChange = (checked) => handleCategoryToggle(categoryName, checked, docId);

  return <div>
    <Checkbox name={categoryName} onChange={handleChange}
      label={label} value={toggleState} />
  </div>;
};

CategorySelector.propTypes = {
  category: PropTypes.shape({
    humanName: PropTypes.string.isRequired,
    svg: PropTypes.func.isRequired
  }).isRequired,
  categoryName: PropTypes.string.isRequired
};

const ConnectedCategorySelector = connect(
  (state) => _.pick(state, 'document'),
  (dispatch) => ({
    handleCategoryToggle(categoryName, toggleState, docId) {
      dispatch({
        type: Constants.TOGGLE_DOCUMENT_CATEGORY,
        payload: {
          categoryName,
          toggleState,
          docId
        }
      });
    }
  })
)(CategorySelector);

// PdfSidebar shows relevant document information and comments.
// It is intended to be used with the PdfUI component to
// show a PDF with its corresponding information.
export default class PdfSidebar extends React.Component {
  render() {
    let comments = [];

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
          <ul className="cf-document-category-picker">
            {
              _(Constants.documentCategories).
                toPairs().
                // eslint-disable-next-line no-unused-vars
                sortBy(([name, category]) => category.renderOrder).
                map(
                  ([categoryName, category]) => <li key={categoryName}>
                    <ConnectedCategorySelector category={category}
                      categoryName={categoryName} docId={this.props.doc.id} />
                  </li>
                ).
                value()
            }
          </ul>
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
