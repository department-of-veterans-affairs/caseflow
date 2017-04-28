import React, { PropTypes } from 'react';
import PdfUI from '../components/PdfUI';
import PdfSidebar from '../components/PdfSidebar';
import Modal from '../components/Modal';
import { connect } from 'react-redux';
import { handleClearCommentState, handlePlaceComment,
  handleWriteComment, handleSelectCommentIcon, selectCurrentPdf } from '../reader/actions';
import { PLACING_COMMENT_STATE, WRITING_COMMENT_STATE } from './constants';

// PdfViewer is a smart component that renders the entire
// PDF view of the Reader SPA. It displays the PDF with UI
// as well as the sidebar for comments and document information.
export class PdfViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      comments: [],
      editingComment: null,
      onSaveCommentAdd: null,
      onConfirmDelete: null
    };

    this.props.annotationStorage.setOnCommentChange(this.onCommentChange);
  }

  onCommentChange = (documentId = this.props.doc.id) => {
    this.setState({
      comments: [...this.props.annotationStorage.getAnnotationByDocumentId(documentId)]
    });
  }

  closeConfirmDeleteModal = () => {
    this.setState({
      onConfirmDelete: null
    });
  }

  onDeleteComment = (uuid) => {
    let onConfirmDelete = () => {
      this.props.annotationStorage.deleteAnnotation(
        this.props.doc.id,
        uuid
      );
      this.closeConfirmDeleteModal();
    };

    this.setState({
      onConfirmDelete
    });
  }

  onEditComment = (uuid) => {
    if (!this.isUserActive()) {
      this.setState({
        editingComment: uuid
      });
    }
  }

  onSaveCommentEdit = (comment) => {
    this.props.annotationStorage.getAnnotation(
      this.props.doc.id,
      this.state.editingComment
    ).then((annotation) => {
      annotation.comment = comment;
      this.props.annotationStorage.editAnnotation(
        this.props.doc.id,
        annotation.uuid,
        annotation
      );
    });
    this.onCancelCommentEdit();
  }

  onCancelCommentEdit = () => {
    this.setState({
      editingComment: null
    });
  }

  onAddComment = () => {
    if (!this.isUserActive()) {
      this.props.handlePlaceComment();
    }
  }

  placeComment = (pageNumber, coordinates) => {
    if (this.props.commentFlowState === PLACING_COMMENT_STATE) {
      let annotation = {
        class: 'Annotation',
        page: pageNumber,
        type: 'point',
        x: coordinates.xPosition,
        y: coordinates.yPosition
      };

      this.props.handleWriteComment();
      this.setState({
        onSaveCommentAdd: this.onSaveCommentAdd(annotation, pageNumber)
      });
    }
  }

  onSaveCommentAdd = (annotation, pageNumber) => (content) => {
    annotation.comment = content;
    this.props.annotationStorage.addAnnotation(
      this.props.doc.id,
      pageNumber,
      annotation
    ).then((savedAnnotation) => {
      this.props.handleSelectCommentIcon(savedAnnotation);
    });
    this.onCancelCommentAdd();
  }

  onCancelCommentAdd = () => {
    this.props.handleClearCommentState();
    this.setState({
      onSaveCommentAdd: null
    });
  }

  onIconMoved = (uuid, coordinates, page) => {
    this.props.annotationStorage.getAnnotation(
      this.props.doc.id,
      uuid
    ).then((annotation) => {
      annotation.x = coordinates.x;
      annotation.y = coordinates.y;
      annotation.page = page;
      this.props.annotationStorage.editAnnotation(
        this.props.doc.id,
        annotation.uuid,
        annotation
      );
    });
  }

  // Returns true if the user is doing some action. i.e.
  // editing a note, adding a note, or placing a comment.
  isUserActive = () => this.state.editingComment !== null ||
      this.props.commentFlowState

  keyListener = (event) => {
    if (!this.isUserActive()) {
      if (event.key === 'ArrowLeft' && this.props.prevDocId) {
        this.props.selectCurrentPdf(this.props.prevDocId);
      }
      if (event.key === 'ArrowRight' && this.props.nextDocId) {
        this.props.selectCurrentPdf(this.props.nextDocId);
      }
    }
  }

  onCommentClick = (uuid) => {
    let comments = [...this.state.comments];

    comments = comments.map((comment) => {
      let copy = { ...comment };

      if (comment.uuid === uuid) {
        copy.selected = true;
      } else {
        copy.selected = false;
      }

      return copy;
    });
    this.setState({ comments });
  }

  componentDidUpdate = () => {
    if (this.props.commentFlowState === WRITING_COMMENT_STATE) {
      let commentBox = document.getElementById('addComment');

      commentBox.focus();
    }
  }
  componentDidMount = () => {
    this.onCommentChange();

    window.addEventListener('keydown', this.keyListener);
  }

  componentWillUnmount = () => {
    window.removeEventListener('keydown', this.keyListener);
  }

  componentWillReceiveProps = (nextProps) => {
    if (nextProps.doc.id !== this.props.doc.id) {
      this.onCommentChange(nextProps.doc.id);
    }

    if (nextProps.scrollToComment &&
        nextProps.scrollToComment !== this.props.scrollToComment) {
      this.onCommentClick(nextProps.scrollToComment.id);
    }
  }

  render() {
    return (
      <div>
        <div className="cf-pdf-page-container">
          <PdfUI
            comments={this.state.comments}
            doc={this.props.doc}
            file={this.props.file}
            pdfWorker={this.props.pdfWorker}
            id="pdf"
            onPageClick={this.placeComment}
            onShowList={this.props.onShowList}
            prevDocId={this.props.prevDocId}
            nextDocId={this.props.nextDocId}
            onViewPortCreated={this.onViewPortCreated}
            onViewPortsCleared={this.onViewPortsCleared}
            onCommentClick={this.onCommentClick}
            onCommentScrolledTo={this.props.onCommentScrolledTo}
            onIconMoved={this.onIconMoved}
          />
          <PdfSidebar
            addNewTag={this.props.addNewTag}
            removeTag={this.props.removeTag}
            showTagErrorMsg={this.props.showTagErrorMsg}
            doc={this.props.doc}
            editingComment={this.state.editingComment}
            onAddComment={this.onAddComment}
            comments={this.state.comments}
            onSaveCommentAdd={this.state.onSaveCommentAdd}
            onCancelCommentAdd={this.onCancelCommentAdd}
            onSaveCommentEdit={this.onSaveCommentEdit}
            onCancelCommentEdit={this.onCancelCommentEdit}
            onDeleteComment={this.onDeleteComment}
            onEditComment={this.onEditComment}
            onJumpToComment={this.props.onJumpToComment}
          />
        </div>
        {this.state.onConfirmDelete && <Modal
          buttons={[
            { classNames: ['cf-modal-link', 'cf-btn-link'],
              name: 'Cancel',
              onClick: this.closeConfirmDeleteModal
            },
            { classNames: ['usa-button', 'usa-button-secondary'],
              name: 'Confirm delete',
              onClick: this.state.onConfirmDelete
            }
          ]}
          closeHandler={this.closeConfirmDeleteModal}
          title="Delete Comment">
          Are you sure you want to delete this comment?
        </Modal>}
      </div>
    );
  }
}

const mapStateToProps = (state) => {
  return {
    commentFlowState: state.ui.pdf.commentFlowState,
    scrollToComment: state.ui.pdf.scrollToComment,
    hidePdfSidebar: state.ui.pdf.hidePdfSidebar
  };
};
const mapDispatchToProps = (dispatch) => ({
  handlePlaceComment: () => dispatch(handlePlaceComment()),
  handleWriteComment: () => dispatch(handleWriteComment()),
  handleClearCommentState: () => dispatch(handleClearCommentState()),
  selectCurrentPdf: (docId) => dispatch(selectCurrentPdf(docId)),
  handleSelectCommentIcon: (comment) => dispatch(handleSelectCommentIcon(comment))
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfViewer);

PdfViewer.propTypes = {
  annotationStorage: PropTypes.object,
  doc: PropTypes.object,
  file: PropTypes.string.isRequired,
  pdfWorker: PropTypes.string,
  scrollToComment: PropTypes.shape({
    id: React.PropTypes.number
  }),
  onScrollToComment: PropTypes.func,
  onCommentScrolledTo: PropTypes.func,
  handlePlaceComment: PropTypes.func,
  handleWriteComment: PropTypes.func,
  handleClearCommentState: PropTypes.func,
  handleSelectCommentIcon: PropTypes.func,
  nextDocId: PropTypes.number,
  prevDocId: PropTypes.number,
  selectCurrentPdf: PropTypes.func,
  hidePdfSidebar: PropTypes.bool
};
