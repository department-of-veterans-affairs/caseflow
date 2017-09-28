import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';

import Comment from './Comment';
import EditComment from './EditComment';
import Button from '../components/Button';
import Modal from '../components/Modal';
import Table from '../components/Table';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import Accordion from '../components/Accordion';
import AccordionSection from '../components/AccordionSection';
import { plusIcon, Keyboard } from '../components/RenderFunctions';
import SideBarDocumentInformation from './SideBarDocumentInformation';
import SideBarCategories from './SideBarCategories';
import SideBarIssueTags from './SideBarIssueTags';
import * as Constants from '../reader/constants';
import { toggleDocumentCategoryFail, startPlacingAnnotation, createAnnotation, updateAnnotationContent,
  startEditAnnotation, cancelEditAnnotation, requestEditAnnotation, stopPlacingAnnotation,
  updateNewAnnotationContent, selectAnnotation, setOpenedAccordionSections, togglePdfSidebar
  } from '../reader/actions';
import ApiUtil from '../util/ApiUtil';
import { categoryFieldNameOfCategoryName, keyOfAnnotation, sortAnnotations }
  from './utils';
import { scrollColumns, scrollInstructions, commentColumns, commentInstructions, documentsColumns,
  documentsInstructions } from './PdfKeyboardInfo';
import classNames from 'classnames';
import { makeGetAnnotationsByDocumentId } from './selectors';
import { INTERACTION_TYPES, CATEGORIES, ENDPOINT_NAMES } from './analytics';

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

      window.analyticsEvent(
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

  stopPlacingAnnotation = () => this.props.stopPlacingAnnotation('from-canceling-new-annotation');

  onAccordionOpenOrClose = (openedSections) =>
    this.props.setOpenedAccordionSections(openedSections, this.props.openedAccordionSections)

  handleAddClick = (event) => {
    this.props.startPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI);
    event.stopPropagation();
  }
  render() {
    let comments = [];

    const {
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

    return <div className={sidebarClass}>
        <div className="cf-sidebar-header">
          <Button
            name="hide menu"
            classNames={['cf-pdf-button']}
            id="hide-menu-header"
            onClick={this.props.togglePdfSidebar}>
            <h2 className="cf-non-stylized-header">
              Hide menu <i className="fa fa-chevron-right" aria-hidden="true"></i>
            </h2>
          </Button>
        </div>
        <div className="cf-sidebar-accordion" id="cf-sidebar-accordion" ref={(commentListElement) => {
          this.commentListElement = commentListElement;
        }}>
          <Accordion style="outline"
            onChange={this.onAccordionOpenOrClose}
            activeKey={this.props.openedAccordionSections}>
            <AccordionSection title="Document information">
              <SideBarDocumentInformation appeal={appeal} doc={this.props.doc}/>
            </AccordionSection>
            <AccordionSection title="Categories">
              <SideBarCategories doc={this.props.doc}
                documents={this.props.documents}
                showErrorMessage={showErrorMessage}
                handleCategoryToggle={
                  _.partial(this.props.handleCategoryToggle, this.props.doc.id)
                }/>
            </AccordionSection>
            <AccordionSection title="Issue tags">
              <SideBarIssueTags
                doc={this.props.doc}
                showErrorMessage={showErrorMessage}
                tagOptions={tagOptions}
                addNewTag={this.props.addNewTag}
                removeTag={this.props.removeTag}/>
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
                {showErrorMessage.annotation && <CannotSaveAlert />}
                <div className="cf-pdf-comment-list">
                  {this.props.placedButUnsavedAnnotation &&
                    <EditComment
                      comment={this.props.placedButUnsavedAnnotation}
                      id="addComment"
                      disableOnEmpty={true}
                      onChange={this.props.updateNewAnnotationContent}
                      onCancelCommentEdit={this.stopPlacingAnnotation}
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
    ..._.pick(state.readerReducer.ui, 'placedButUnsavedAnnotation', 'selectedAnnotationId'),
    comments: makeGetAnnotationsByDocumentId(state.readerReducer)(ownProps.doc.id),
    scrollToSidebarComment: state.readerReducer.ui.pdf.scrollToSidebarComment,
    hidePdfSidebar: state.readerReducer.ui.pdf.hidePdfSidebar,
    showErrorMessage: state.readerReducer.ui.pdfSidebar.showErrorMessage,
    appeal: state.readerReducer.loadedAppeal,
    tagOptions: state.readerReducer.ui.tagOptions,
    ..._.pick(state.readerReducer, 'documents', 'openedAccordionSections')
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
      { data: { [categoryKey]: toggleState } },
      ENDPOINT_NAMES.DOCUMENT
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
