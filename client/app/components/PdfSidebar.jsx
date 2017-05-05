import React, { PropTypes } from 'react';
import { bindActionCreators } from 'redux';
import { formatDateStr } from '../util/DateUtil';
import Comment from '../components/Comment';
import SearchableDropdown from '../components/SearchableDropdown';
import EditComment from '../components/EditComment';
import _ from 'lodash';
import Alert from '../components/Alert';
import Button from '../components/Button';
import { connect } from 'react-redux';
import * as Constants from '../reader/constants';
import { toggleDocumentCategoryFail, startPlacingAnnotation, createAnnotation, 
  startEditAnnotation } from '../reader/actions';
import ApiUtil from '../util/ApiUtil';
import { categoryFieldNameOfCategoryName, keyOfAnnotation } from '../reader/utils';
import DocCategoryPicker from '../reader/DocCategoryPicker';
import { plusIcon } from './RenderFunctions';
import classNames from 'classnames';
import { getAnnotationByDocumentId, sortAnnotations } from '../reader/util/AnnotationUtil';

const COMMENT_SCROLL_FROM_THE_TOP = 50;

// PdfSidebar shows relevant document information and comments.
// It is intended to be used with the PdfUI component to
// show a PDF with its corresponding information.
export class PdfSidebar extends React.Component {
  constructor(props) {
    super(props);

    this.commentElements = {};
  }

  componentDidUpdate = () => {
    if (this.props.scrollToSidebarComment) {
      const commentListBoundingBox = this.commentListElement.getBoundingClientRect();

      this.commentListElement.scrollTop = this.commentListElement.scrollTop +
        this.commentElements[
          this.props.scrollToSidebarComment.id
        ].getBoundingClientRect().top - commentListBoundingBox.top -
        COMMENT_SCROLL_FROM_THE_TOP;
      this.props.handleFinishScrollToSidebarComment();
    }
  }

  generateOptionsFromTags = (tags) =>
    _(tags).
      reject('pendingRemoval').
      map((tag) => ({
        value: tag.text,
        label: tag.text,
        tagId: tag.id })
      ).
      value();

  onChange = (values, deletedValue) => {
    if (_.size(deletedValue)) {
      const tagValue = _.first(deletedValue).label;
      const result = _.find(this.props.doc.tags, { text: tagValue });

      this.props.removeTag(this.props.doc, result.id);
    } else if (values && values.length) {
      this.props.addNewTag(this.props.doc, values);
    }
  }

  render() {
    let comments = [];

    const {
      doc,
      showErrorMessage,
      tagOptions
    } = this.props;

    comments = sortAnnotations(this.props.comments).map((comment, index) => {
      if (comment.uuid === this.props.currentlyEditingAnnotationId) {
        return <EditComment
            id="editCommentBox"
            onCancelCommentEdit={this.props.onCancelCommentEdit}
            onSaveCommentEdit={this.props.onSaveCommentEdit}
            key={keyOfAnnotation(comment)}
          >
            {comment.comment}
          </EditComment>;
      }

      return <div ref={(commentElement) => {
        this.commentElements[comment.id] = commentElement;
      }}
        key={keyOfAnnotation(comment)}>
        <Comment
          id={`comment${index}`}
          selected={false}
          onEditComment={this.props.startEditAnnotation}
          uuid={comment.uuid}
          selected={comment.selected}
          onClick={this.props.onJumpToComment(comment)}
          page={comment.page}>
            {comment.comment}
          </Comment>
        </div>;
    });

    const sidebarClass = classNames(
      'cf-sidebar-wrapper',
      { 'hidden-sidebar': this.props.hidePdfSidebar });
    const categoryToggleStates = _.mapValues(
      Constants.documentCategories,
      (val, key) =>
        this.props.documents[this.props.doc.id][categoryFieldNameOfCategoryName(key)]
    );

    const cannotSaveAlert = <Alert type="error" message="Unable to save. Please try again." />;

    return <div className={sidebarClass}>
        <div className="cf-sidebar-header">
          <Button
            name="hide menu"
            classNames={['cf-pdf-button']}
            onClick={this.props.handleTogglePdfSidebar}>
            <strong>
              Hide menu <i className="fa fa-chevron-right" aria-hidden="true"></i>
            </strong>
          </Button>
        </div>
        <div className="cf-document-info-wrapper">
          <p className="cf-pdf-meta-title cf-pdf-cutoff">
            <b>Document Type: </b>
            <span title={this.props.doc.type}>
              {this.props.doc.type}
            </span>
          </p>
          <p className="cf-pdf-meta-title">
            <b>Receipt Date:</b> {formatDateStr(this.props.doc.receivedAt)}
          </p>
          {showErrorMessage.category && cannotSaveAlert}
          <DocCategoryPicker
            handleCategoryToggle={
              _.partial(this.props.handleCategoryToggle, this.props.doc.id)
            }
            categoryToggleStates={categoryToggleStates} />
          <div className="cf-sidebar-heading cf-sidebar-heading-related-issues">
            Related Issues
          </div>
          {showErrorMessage.tag && cannotSaveAlert}
          <SearchableDropdown
            name="tags"
            label="Select or tag issue(s)"
            multi={true}
            creatable={true}
            options={this.generateOptionsFromTags(tagOptions)}
            placeholder=""
            value={this.generateOptionsFromTags(doc.tags)}
            onChange={this.onChange}
            selfManageValueState={true}
          />
          <div className="cf-sidebar-heading">
            Comments
            <span className="cf-right-side cf-add-comment-button">
              <Button
                name="AddComment"
                onClick={this.props.startPlacingAnnotation}>
                <span>{ plusIcon() } &nbsp; Add a comment</span>
              </Button>
            </span>
          </div>
        </div>

        <div id="cf-comment-wrapper" className="cf-comment-wrapper"
          ref={(commentListElement) => {
            this.commentListElement = commentListElement;
          }}>
          {showErrorMessage.comment && cannotSaveAlert}
          <div className="cf-pdf-comment-list">
            {this.props.placedButUnsavedAnnotation &&
              <EditComment
                id="addComment"
                onCancelCommentEdit={this.props.onCancelCommentAdd}
                onSaveCommentEdit={_.partial(this.props.createAnnotation, this.props.placedButUnsavedAnnotation)} />}
            {comments}
          </div>
        </div>
      </div>;
  }
}

PdfSidebar.propTypes = {
  doc: PropTypes.object,
  comments: React.PropTypes.arrayOf(React.PropTypes.shape({
    comment: React.PropTypes.string,
    uuid: React.PropTypes.number
  })),
  currentlyEditingAnnotationId: React.PropTypes.number,
  isWritingComment: PropTypes.bool,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func,
  onCancelCommentAdd: PropTypes.func,
  onJumpToComment: PropTypes.func,
  handleTogglePdfSidebar: PropTypes.func,
  commentFlowState: PropTypes.string,
  showErrorMessage: PropTypes.shape({
    tag: PropTypes.bool,
    category: PropTypes.bool,
    comment: PropTypes.bool
  }),
  scrollToSidebarComment: PropTypes.shape({
    id: React.PropTypes.number
  }),
  hidePdfSidebar: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  return {
    ..._.pick(state.ui, 'placedButUnsavedAnnotation', 'currentlyEditingAnnotationId'),
    comments: getAnnotationByDocumentId(state, ownProps.doc.id),
    scrollToSidebarComment: state.ui.pdf.scrollToSidebarComment,
    commentFlowState: state.ui.pdf.commentFlowState,
    hidePdfSidebar: state.ui.pdf.hidePdfSidebar,
    showErrorMessage: state.ui.pdfSidebar.showErrorMessage,
    documents: state.documents,
    tagOptions: state.tagOptions
  };
};
const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    startPlacingAnnotation,
    createAnnotation,
    startEditAnnotation
  }, dispatch),

  handleFinishScrollToSidebarComment() {
    dispatch({
      type: Constants.SCROLL_TO_SIDEBAR_COMMENT,
      payload: {
        scrollToSidebarComment: null
      }
    });
  },
  handleCategoryToggle(docId, categoryName, toggleState) {
    const categoryKey = categoryFieldNameOfCategoryName(categoryName);

    ApiUtil.patch(
      `/document/${docId}`,
      { data: { [categoryKey]: toggleState } }
    ).catch(() =>
      dispatch(toggleDocumentCategoryFail(docId, categoryKey, !toggleState))
    );

    dispatch({
      type: Constants.TOGGLE_DOCUMENT_CATEGORY,
      payload: {
        categoryKey,
        toggleState,
        docId
      }
    });
  },
  handleTogglePdfSidebar() {
    dispatch({
      type: Constants.TOGGLE_PDF_SIDEBAR
    });
  }
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfSidebar);
