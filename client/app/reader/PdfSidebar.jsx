import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import classNames from 'classnames';

import { Accordion } from '../components/Accordion';
import { CATEGORIES } from './analytics';
import { COMMENT_ACCORDION_KEY } from '../reader/PdfViewer/actionTypes';
import { Keyboard } from '../components/RenderFunctions';
import { commentColumns, commentInstructions, documentsColumns,
  documentsInstructions, searchColumns, searchInstructions,
  categoryColumns, categoryInstructions } from './PdfKeyboardInfo';
import { keyOfAnnotation, sortAnnotations }
  from './utils';
import { makeGetAnnotationsByDocumentId } from './selectors';
import {
  selectAnnotation, startEditAnnotation, requestEditAnnotation, cancelEditAnnotation,
  updateAnnotationContent, updateAnnotationRelevantDate
} from '../reader/AnnotationLayer/AnnotationActions';
import { setOpenedAccordionSections, togglePdfSidebar,
  handleFinishScrollToSidebarComment } from '../reader/PdfViewer/PdfViewerActions';
import AccordionSection from '../components/AccordionSection';
import Button from '../components/Button';
import Comment from './Comment';
import EditComment from './EditComment';
import Modal from '../components/Modal';
import SideBarCategories from './SideBarCategories';
import SideBarComments from './SideBarComments';
import SideBarDocumentInformation from './SideBarDocumentInformation';
import SideBarIssueTags from './SideBarIssueTags';
import Table from '../components/Table';
import WindowSlider from './WindowSlider';

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
    if (this.props.scrollToSidebarComment && this.commentElements[this.props.scrollToSidebarComment.id]) {
      const commentListBoundingBox = this.commentListElement.getBoundingClientRect();

      this.commentListElement.scrollTop = this.commentListElement.scrollTop +
        this.commentElements[
          this.props.scrollToSidebarComment.id
        ].getBoundingClientRect().top - commentListBoundingBox.top -
        COMMENT_SCROLL_FROM_THE_TOP;
      this.props.handleFinishScrollToSidebarComment();
    }
  }

  componentDidMount() {
    window.addEventListener('keydown', this.keyHandler);
  }

  componentWillUnmount() {
    window.removeEventListener('keydown', this.keyHandler);
  }

  keyHandler = (event) => {
    if (event.altKey &&
        event.code === 'KeyM' &&
        !event.shiftKey) {
      this.props.togglePdfSidebar();
    }
  }

  onAccordionOpenOrClose = (openedSections) =>
    this.props.setOpenedAccordionSections(openedSections, this.props.openedAccordionSections)

  render() {
    let comments = [];

    const { appeal } = this.props;
    const sideBarSmall = '250px';
    const sideBarLarge = '380px';

    comments = sortAnnotations(this.props.comments).map((comment, index) => {
      if (comment.editing) {
        return <EditComment
          id={`editCommentBox-${keyOfAnnotation(comment)}`}
          comment={comment}
          onCancelCommentEdit={this.props.cancelEditAnnotation}
          onChange={this.props.updateAnnotationContent}
          onChangeDate={this.props.updateAnnotationRelevantDate}
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
          page={comment.page}
          date={comment.relevant_date}>
          {comment.comment}
        </Comment>
      </div>;
    });

    const sidebarClass = classNames(
      'cf-sidebar-wrapper',
      { 'hidden-sidebar': this.props.hidePdfSidebar });

    const sidebarWrapper = css({
      width: '28%',
      minWidth: sideBarSmall,
      maxWidth: sideBarLarge,
      '@media(max-width: 920px)': { width: sideBarSmall },
      '@media(min-width: 1240px)': { width: sideBarLarge }
    });

    return <div className={sidebarClass} {...sidebarWrapper}>
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
        { this.props.featureToggles.windowSlider && <WindowSlider /> }
        <Accordion style="outline"
          onChange={this.onAccordionOpenOrClose}
          activeKey={this.props.openedAccordionSections}>
          <AccordionSection title="Document information">
            <SideBarDocumentInformation appeal={appeal} doc={this.props.doc} />
          </AccordionSection>
          <AccordionSection title="Categories">
            <SideBarCategories doc={this.props.doc} />
          </AccordionSection>
          <AccordionSection title="Issue tags">
            <SideBarIssueTags
              doc={this.props.doc} />
          </AccordionSection>
          <AccordionSection title={COMMENT_ACCORDION_KEY} id="comments-header">
            <SideBarComments
              comments={comments}
            />
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
            noDivider
            id="cf-keyboard-modal">
            <div className="cf-keyboard-modal-scroll">
              <Table
                columns={documentsColumns}
                rowObjects={documentsInstructions}
                slowReRendersAreOk
                className="cf-keyboard-modal-table" />
              <Table
                columns={searchColumns}
                rowObjects={searchInstructions}
                slowReRendersAreOk
                className="cf-keyboard-modal-table" />
              <Table
                columns={commentColumns}
                rowObjects={commentInstructions}
                slowReRendersAreOk
                className="cf-keyboard-modal-table" />
              <Table
                columns={categoryColumns}
                rowObjects={categoryInstructions}
                slowReRendersAreOk
                className="cf-keyboard-modal-table" />
            </div>
          </Modal>
        </div>
        }
      </div>
    </div>;
  }
}

PdfSidebar.propTypes = {
  appeal: PropTypes.object,
  doc: PropTypes.object,
  selectedAnnotationId: PropTypes.number,
  comments: PropTypes.arrayOf(PropTypes.shape({
    comment: PropTypes.string,
    uuid: PropTypes.number
  })),
  featureToggles: PropTypes.array,
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
      message: PropTypes.string
    }),
    category: PropTypes.shape({
      visible: PropTypes.bool,
      message: PropTypes.string
    }),
    comment: PropTypes.shape({
      visible: PropTypes.bool,
      message: PropTypes.string
    })
  }),
  scrollToSidebarComment: PropTypes.shape({
    id: PropTypes.number
  }),
  hidePdfSidebar: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  return {
    ..._.pick(state.annotationLayer, 'placedButUnsavedAnnotation', 'selectedAnnotationId'),
    comments: makeGetAnnotationsByDocumentId(state)(ownProps.doc.id),
    scrollToSidebarComment: state.pdfViewer.scrollToSidebarComment,
    error: state.pdfViewer.pdfSideBarError,
    appeal: state.pdfViewer.loadedAppeal,
    openedAccordionSections: state.pdfViewer.openedAccordionSections,
    hidePdfSidebar: state.pdfViewer.hidePdfSidebar
  };
};
const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    togglePdfSidebar,
    setOpenedAccordionSections,
    selectAnnotation,
    startEditAnnotation,
    updateAnnotationContent,
    updateAnnotationRelevantDate,
    cancelEditAnnotation,
    requestEditAnnotation,
    handleFinishScrollToSidebarComment
  }, dispatch)
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfSidebar);
