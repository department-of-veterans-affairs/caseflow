import classNames from 'classnames';
import { css } from 'glamor';
import _ from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { Accordion } from '../components/Accordion';
import AccordionSection from '../components/AccordionSection';
import Button from '../components/Button';
import { KeyboardIcon } from '../components/icons/KeyboardIcon';
import Modal from '../components/Modal';
import Table from '../components/Table';
import { CATEGORIES } from '../reader/analytics';
import {
  cancelEditAnnotation,
  requestEditAnnotation,
  selectAnnotation,
  startEditAnnotation,
  updateAnnotationContent,
  updateAnnotationRelevantDate,
} from '../reader/AnnotationLayer/AnnotationActions';
import Comment from '../reader/Comment';
import EditComment from '../reader/EditComment';
import {
  categoryColumns,
  categoryInstructions,
  commentColumns,
  commentInstructions,
  documentsColumns,
  documentsInstructions,
  searchColumns,
  searchInstructions,
} from '../reader/PdfKeyboardInfo';
import { COMMENT_ACCORDION_KEY } from '../reader/PdfViewer/actionTypes';
import {
  fetchAppealDetails,
  handleFinishScrollToSidebarComment,
  setOpenedAccordionSections,
  togglePdfSidebar,
} from '../reader/PdfViewer/PdfViewerActions';
import { makeGetAnnotationsByDocumentId } from '../reader/selectors';
import SideBarCategories from '../reader/SideBarCategories';
import SideBarComments from '../reader/SideBarComments';
import SideBarDocumentInformation from '../reader/SideBarDocumentInformation';
import SideBarIssueTags from '../reader/SideBarIssueTags';
import { keyOfAnnotation, shouldFetchAppeal, sortAnnotations } from '../reader/utils';

const COMMENT_SCROLL_FROM_THE_TOP = 50;

// PdfSidebar shows relevant document information and comments.
// It is intended to be used with the PdfUI component to
// show a PDF with its corresponding information.
export class R2SideBar extends React.Component {
  constructor(props) {
    super(props);

    this.commentElements = {};
    this.state = {
      modal: false,
    };
  }

  handleKeyboardModalClose = () => this.toggleKeyboardModal('modal-close-handler');
  closeKeyboardModalFromButton = () => this.toggleKeyboardModal('modal-got-it-button');
  openKeyboardModal = () => this.toggleKeyboardModal('view-shortcuts-button');

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
        modal: nextStateModalIsOpen,
      };
    });
  };

  componentDidUpdate = () => {
    if (this.props.scrollToSidebarComment && this.commentElements[this.props.scrollToSidebarComment.id]) {
      const commentListBoundingBox = this.commentListElement.getBoundingClientRect();

      this.commentListElement.scrollTop =
        this.commentListElement.scrollTop +
        this.commentElements[this.props.scrollToSidebarComment.id].getBoundingClientRect().top -
        commentListBoundingBox.top -
        COMMENT_SCROLL_FROM_THE_TOP;
      this.props.handleFinishScrollToSidebarComment();
    }
  };

  componentDidMount() {
    window.addEventListener('keydown', this.keyHandler);
    if (shouldFetchAppeal(this.props.appeal, this.props.vacolsId)) {
      this.props.fetchAppealDetails(this.props.vacolsId);
    }
  }

  componentWillUnmount() {
    window.removeEventListener('keydown', this.keyHandler);
  }

  keyHandler = (event) => {
    if (event.altKey && event.code === 'KeyM' && !event.shiftKey) {
      this.props.togglePdfSidebar();
    }
  };

  onAccordionOpenOrClose = (openedSections) =>
    this.props.setOpenedAccordionSections(openedSections, this.props.openedAccordionSections);

  render() {
    let comments = [];
    const sideBarSmall = '250px';
    const sideBarLarge = '380px';

    comments = sortAnnotations(this.props.comments).map((comment, index) => {
      if (comment.editing) {
        return (
          <EditComment
            id={`editCommentBox-${keyOfAnnotation(comment)}`}
            comment={comment}
            onCancelCommentEdit={this.props.cancelEditAnnotation}
            onChange={this.props.updateAnnotationContent}
            onChangeDate={this.props.updateAnnotationRelevantDate}
            value={comment.comment}
            onSaveCommentEdit={this.props.requestEditAnnotation}
            key={keyOfAnnotation(comment)}
          />
        );
      }

      const handleClick = () => {
        this.props.onJumpToComment(comment)();
        this.props.selectAnnotation(comment.id);
      };

      return (
        <div
          ref={(commentElement) => {
            this.commentElements[comment.id] = commentElement;
          }}
          key={keyOfAnnotation(comment)}
        >
          <Comment
            id={`comment${index}`}
            onEditComment={this.props.startEditAnnotation}
            uuid={comment.uuid}
            selected={comment.id === this.props.selectedAnnotationId}
            onClick={handleClick}
            page={comment.page}
            date={comment.relevant_date}
          >
            {comment.comment}
          </Comment>
        </div>
      );
    });

    const sidebarClass = classNames('cf-sidebar-wrapper', { 'hidden-sidebar': this.props.hidePdfSidebar });

    const sidebarWrapper = css({
      width: '28%',
      minWidth: sideBarSmall,
      maxWidth: sideBarLarge,
      '@media(max-width: 920px)': { width: sideBarSmall },
      '@media(min-width: 1240px)': { width: sideBarLarge },
    });

    return (
      <div className={sidebarClass} {...sidebarWrapper}>
        <div className="cf-sidebar-header">
          <Button
            name="hide menu"
            classNames={['cf-pdf-button']}
            id="hide-menu-header"
            onClick={this.props.togglePdfSidebar}
          >
            <h2 className="cf-non-stylized-header">
              Hide menu <i className="fa fa-chevron-right" aria-hidden="true" />
            </h2>
          </Button>
        </div>
        <div
          className="cf-sidebar-accordion"
          id="cf-sidebar-accordion"
          ref={(commentListElement) => {
            this.commentListElement = commentListElement;
          }}
        >
          <Accordion
            style="outline"
            onChange={this.onAccordionOpenOrClose}
            activeKey={this.props.openedAccordionSections}
          >
            <AccordionSection title="Document information">
              <SideBarDocumentInformation appeal={this.props.appeal} doc={this.props.doc} />
            </AccordionSection>
            <AccordionSection title="Categories">
              <SideBarCategories doc={this.props.doc} />
            </AccordionSection>
            <AccordionSection title="Issue tags">
              <SideBarIssueTags doc={this.props.doc} />
            </AccordionSection>
            <AccordionSection title={COMMENT_ACCORDION_KEY} id="comments-header">
              <SideBarComments comments={comments} />
            </AccordionSection>
          </Accordion>
        </div>
        <div className="cf-keyboard-shortcuts">
          <Button
            id="cf-open-keyboard-modal"
            name={
              <span>
                <KeyboardIcon />
                &nbsp; View keyboard shortcuts
              </span>
            }
            onClick={this.openKeyboardModal}
            classNames={['cf-btn-link']}
          />
          {this.state.modal && (
            <div className="cf-modal-scroll">
              <Modal
                buttons={[
                  {
                    classNames: ['usa-button', 'usa-button-secondary'],
                    name: 'Thanks, got it!',
                    onClick: this.closeKeyboardModalFromButton,
                  },
                ]}
                closeHandler={this.handleKeyboardModalClose}
                title="Keyboard shortcuts"
                noDivider
                id="cf-keyboard-modal"
              >
                <div className="cf-keyboard-modal-scroll">
                  <Table
                    columns={documentsColumns}
                    rowObjects={documentsInstructions}
                    slowReRendersAreOk
                    className="cf-keyboard-modal-table"
                  />
                  <Table
                    columns={searchColumns}
                    rowObjects={searchInstructions}
                    slowReRendersAreOk
                    className="cf-keyboard-modal-table"
                  />
                  <Table
                    columns={commentColumns}
                    rowObjects={commentInstructions}
                    slowReRendersAreOk
                    className="cf-keyboard-modal-table"
                  />
                  <Table
                    columns={categoryColumns}
                    rowObjects={categoryInstructions}
                    slowReRendersAreOk
                    className="cf-keyboard-modal-table"
                  />
                </div>
              </Modal>
            </div>
          )}
        </div>
      </div>
    );
  }
}

R2SideBar.propTypes = {
  appeal: PropTypes.object,
  doc: PropTypes.object,
  selectedAnnotationId: PropTypes.number,
  comments: PropTypes.arrayOf(
    PropTypes.shape({
      comment: PropTypes.string,
      uuid: PropTypes.number,
    })
  ),
  featureToggles: PropTypes.array,
  fetchAppealDetails: PropTypes.func,
  openedAccordionSections: PropTypes.array,
  cancelEditAnnotation: PropTypes.func,
  handleFinishScrollToSidebarComment: PropTypes.func,
  onJumpToComment: PropTypes.func,
  requestEditAnnotation: PropTypes.func,
  selectAnnotation: PropTypes.func,
  setOpenedAccordionSections: PropTypes.func,
  startEditAnnotation: PropTypes.func,
  togglePdfSidebar: PropTypes.func,
  updateAnnotationContent: PropTypes.func,
  updateAnnotationRelevantDate: PropTypes.func,
  error: PropTypes.shape({
    tag: PropTypes.shape({
      visible: PropTypes.bool,
      message: PropTypes.string,
    }),
    category: PropTypes.shape({
      visible: PropTypes.bool,
      message: PropTypes.string,
    }),
    comment: PropTypes.shape({
      visible: PropTypes.bool,
      message: PropTypes.string,
    }),
  }),
  scrollToSidebarComment: PropTypes.shape({
    id: PropTypes.number,
  }),
  hidePdfSidebar: PropTypes.bool,
};

const mapStateToProps = (state, ownProps) => {
  return {
    ..._.pick(state.annotationLayer, 'placedButUnsavedAnnotation', 'selectedAnnotationId'),
    comments: makeGetAnnotationsByDocumentId(state)(ownProps.doc.id),
    scrollToSidebarComment: state.pdfViewer.scrollToSidebarComment,
    error: state.pdfViewer.pdfSideBarError,
    appeal: state.pdfViewer.loadedAppeal,
    openedAccordionSections: state.pdfViewer.openedAccordionSections,
    hidePdfSidebar: state.pdfViewer.hidePdfSidebar,
  };
};
const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators(
    {
      togglePdfSidebar,
      setOpenedAccordionSections,
      selectAnnotation,
      startEditAnnotation,
      updateAnnotationContent,
      updateAnnotationRelevantDate,
      cancelEditAnnotation,
      requestEditAnnotation,
      handleFinishScrollToSidebarComment,
      fetchAppealDetails,
    },
    dispatch
  ),
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(R2SideBar);
