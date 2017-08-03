import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { formatDateStr } from '../util/DateUtil';
import Comment from '../components/Comment';
import SearchableDropdown from '../components/SearchableDropdown';
import EditComment from '../components/EditComment';
import _ from 'lodash';
import Alert from '../components/Alert';
import Button from '../components/Button';
import Modal from '../components/Modal';
import Table from '../components/Table';
import Accordion from '../components/Accordion';
import AccordionSection from '../components/AccordionSection';
import LoadingMessage from '../components/LoadingMessage';

import { connect } from 'react-redux';
import * as Constants from '../reader/constants';
import { toggleDocumentCategoryFail, startPlacingAnnotation, createAnnotation, updateAnnotationContent,
  startEditAnnotation, cancelEditAnnotation, requestEditAnnotation, stopPlacingAnnotation,
  updateNewAnnotationContent, selectAnnotation, setOpenedAccordionSections, togglePdfSidebar
  } from '../reader/actions';
import ApiUtil from '../util/ApiUtil';
import { categoryFieldNameOfCategoryName, keyOfAnnotation, sortAnnotations }
  from '../reader/utils';
import DocCategoryPicker from '../reader/DocCategoryPicker';
import { plusIcon, Keyboard } from './RenderFunctions';
import { scrollColumns, scrollInstructions, commentColumns, commentInstructions, documentsColumns,
  documentsInstructions } from './PdfKeyboardInfo';
import classNames from 'classnames';
import { makeGetAnnotationsByDocumentId } from '../reader/selectors';
import { INTERACTION_TYPES, CATEGORIES } from '../reader/analytics';
import Analytics from '../util/AnalyticsUtil';

const COMMENT_SCROLL_FROM_THE_TOP = 50;

// PdfSidebar shows relevant document information and comments.
// It is intended to be used with the PdfUI component to
// show a PDF with its corresponding information.
export class PdfSidebar extends React.Component {
  constructor(props) {
    super(props);

    this.commentElements = {};
    this.state = {
      modal: false
    };
  }

  handleKeyboardModalClose = () => this.toggleKeyboardModal('modal-close-handler')
  closeKeyboardModalFromButton = () => this.toggleKeyboardModal('modal-got-it-button')
  openKeyboardModal = () => this.toggleKeyboardModal('view-shortcuts-button')

  toggleKeyboardModal = (sourceLabel) => {
    this.setState((prevState) => {
      const nextStateModalIsOpen = !prevState.modal;
      const eventActionPrefix = nextStateModalIsOpen ? 'open' : 'close';

      Analytics.event(
        CATEGORIES.VIEW_DOCUMENT_PAGE,
        `${eventActionPrefix}-keyboard-shortcuts-modal`,
        sourceLabel
      );

      return {
        modal: nextStateModalIsOpen
      };
    });
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

  onAccordionOpenOrClose = (openedSections) =>
    this.props.setOpenedAccordionSections(openedSections, this.props.openedAccordionSections)

  handleAddClick = (event) => {
    this.props.startPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI);
    event.stopPropagation();
  }
  render() {
    let comments = [];

    const {
      doc,
      showErrorMessage,
      tagOptions,
      appeal
    } = this.props;

    comments = sortAnnotations(this.props.comments).map((comment, index) => {
      if (comment.editing) {
        return <EditComment
            id={`editCommentBox-${keyOfAnnotation(comment)}`}
            comment={comment}
            onCancelCommentEdit={this.props.cancelEditAnnotation}
            onChange={this.props.updateAnnotationContent}
            value={comment.comment}
            onSaveCommentEdit={this.props.requestEditAnnotation}
            key={keyOfAnnotation(comment)}
          />;
      }

      const handleClick = () => {
        this.props.onJumpToComment(comment)();
        this.props.selectAnnotation(comment.id);
      };

      return <div ref={(commentElement) => {
        this.commentElements[comment.id] = commentElement;
      }}
        key={keyOfAnnotation(comment)}>
        <Comment
          id={`comment${index}`}
          onEditComment={this.props.startEditAnnotation}
          uuid={comment.uuid}
          selected={comment.id === this.props.selectedAnnotationId}
          onClick={handleClick}
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
    console.log(appeal);
    return <div className={sidebarClass}>
        <div className="cf-sidebar-header">
          <Button
            name="hide menu"
            classNames={['cf-pdf-button']}
            id="hide-menu-header"
            onClick={this.props.togglePdfSidebar}>
            <strong>
              Hide menu <i className="fa fa-chevron-right" aria-hidden="true"></i>
            </strong>
          </Button>
        </div>
        <div className="cf-sidebar-accordion" id="cf-sidebar-accordion" ref={(commentListElement) => {
          this.commentListElement = commentListElement;
        }}>
          <Accordion style="outline"
            onChange={this.onAccordionOpenOrClose}
            activeKey={this.props.openedAccordionSections}>
            {appeal && <AccordionSection title="Document information">
              <p className="cf-pdf-meta-title cf-pdf-cutoff">
                <b>Document Type: </b>
                <span title={this.props.doc.type} className="cf-document-type">
                  {this.props.doc.type}
                </span>
              </p>
              <p className="cf-pdf-meta-title">
                <b>Receipt Date:</b> {formatDateStr(this.props.doc.receivedAt)}
              </p>
              <hr />
              { !_.isEmpty(appeal) ?
              <LoadingMessage message="Loading details..." spinnerColor={Constants.READER_COLOR}/> :
              <div>
              <p className="cf-pdf-meta-title">
                <b>Veteran ID:</b> {appeal.vbms_id}
              </p>
              <p className="cf-pdf-meta-title">
                <b>Type:</b> {appeal.type}
              </p>
              <p className="cf-pdf-meta-title">
                <b>Docket Number:</b> {appeal.docket_number}
              </p>
              <p className="cf-pdf-meta-title">
                <b>Regional Office:</b> {`${appeal.regional_office.key} - ${appeal.regional_office.city}`}
              </p>
              <p className="cf-pdf-meta-title">
                <b>Issues</b>
                <ol>
                  {appeal.issues.map((issue) =>
                    <li key={`${issue.appeal_id}_${issue.vacols_sequence_id}`}><span>
                      {issue.type.label}: {issue.levels ? issue.levels.join(', ') : ''}
                    </span></li>
                  )}
                </ol>
              </p>
              </div>
              
              }
            </AccordionSection>}
            <AccordionSection title="Categories">
              <div className="cf-category-sidebar">
                {showErrorMessage.category && cannotSaveAlert}
                <DocCategoryPicker
                  allowReadOnly={true}
                  handleCategoryToggle={
                    _.partial(this.props.handleCategoryToggle, this.props.doc.id)
                  }
                  categoryToggleStates={categoryToggleStates} />
              </div>
            </AccordionSection>
            <AccordionSection title="Issue tags">
              <div className="cf-issue-tag-sidebar">
                {showErrorMessage.tag && cannotSaveAlert}
                <SearchableDropdown
                  key={doc.id}
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
              </div>
            </AccordionSection>
            <AccordionSection title={Constants.COMMENT_ACCORDION_KEY} id="comments-header">
                <span className="cf-right-side cf-add-comment-button">
                  <Button
                    name="AddComment"
                    onClick={this.handleAddClick}>
                    <span>{ plusIcon() } &nbsp; Add a comment</span>
                  </Button>
                </span>
              <div id="cf-comment-wrapper" className="cf-comment-wrapper">
                {showErrorMessage.annotation && cannotSaveAlert}
                <div className="cf-pdf-comment-list">
                  {this.props.placedButUnsavedAnnotation &&
                    <EditComment
                      comment={this.props.placedButUnsavedAnnotation}
                      id="addComment"
                      disableOnEmpty={true}
                      onChange={this.props.updateNewAnnotationContent}
                      onCancelCommentEdit={this.props.stopPlacingAnnotation}
                      onSaveCommentEdit={this.props.createAnnotation} />}
                  {comments}
                </div>
              </div>
            </AccordionSection>
          </Accordion>
        </div>
        <div className="cf-keyboard-shortcuts">
          <Button
              id="cf-open-keyboard-modal"
              name={<span><Keyboard />&nbsp; View keyboard shortcuts</span>}
              onClick={this.openKeyboardModal}
              classNames={['cf-btn-link']}
          />
        { this.state.modal && <div className="cf-modal-scroll">
          <Modal
              buttons = {[
                { classNames: ['usa-button', 'usa-button-secondary'],
                  name: 'Thanks, got it!',
                  onClick: this.closeKeyboardModalFromButton
                }
              ]}
              closeHandler={this.handleKeyboardModalClose}
              title="Keyboard shortcuts"
              noDivider={true}
              id="cf-keyboard-modal">
              <div className="cf-keyboard-modal-scroll">
                <Table
                  columns={scrollColumns}
                  rowObjects={scrollInstructions}
                  slowReRendersAreOk={true}
                  className="cf-keyboard-modal-table"/>
                <Table
                  columns={commentColumns}
                  rowObjects={commentInstructions}
                  slowReRendersAreOk={true}
                  className="cf-keyboard-modal-table"/>
                <Table
                  columns={documentsColumns}
                  rowObjects={documentsInstructions}
                  slowReRendersAreOk={true}
                  className="cf-keyboard-modal-table"/>
              </div>
            </Modal>
        </div>
        }
        </div>
      </div>;
  }
}

PdfSidebar.propTypes = {
  doc: PropTypes.object,
  selectedAnnotationId: PropTypes.number,
  comments: PropTypes.arrayOf(PropTypes.shape({
    comment: PropTypes.string,
    uuid: PropTypes.number
  })),
  onJumpToComment: PropTypes.func,
  togglePdfSidebar: PropTypes.func,
  showErrorMessage: PropTypes.shape({
    tag: PropTypes.bool,
    category: PropTypes.bool,
    comment: PropTypes.bool
  }),
  scrollToSidebarComment: PropTypes.shape({
    id: PropTypes.number
  }),
  hidePdfSidebar: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  return {
    ..._.pick(state.ui, 'placedButUnsavedAnnotation', 'selectedAnnotationId'),
    comments: makeGetAnnotationsByDocumentId(state)(ownProps.doc.id),
    scrollToSidebarComment: state.ui.pdf.scrollToSidebarComment,
    hidePdfSidebar: state.ui.pdf.hidePdfSidebar,
    showErrorMessage: state.ui.pdfSidebar.showErrorMessage,
    appeal: state.loadedAppeal,
    ..._.pick(state, 'documents', 'tagOptions', 'openedAccordionSections')
  };
};
const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    togglePdfSidebar,
    setOpenedAccordionSections,
    selectAnnotation,
    startPlacingAnnotation,
    createAnnotation,
    stopPlacingAnnotation,
    startEditAnnotation,
    updateAnnotationContent,
    updateNewAnnotationContent,
    cancelEditAnnotation,
    requestEditAnnotation
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
      },
      meta: {
        analytics: {
          category: CATEGORIES.VIEW_DOCUMENT_PAGE,
          action: `${toggleState ? 'set' : 'unset'} document category`,
          label: categoryName
        }
      }
    });
  }
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfSidebar);
