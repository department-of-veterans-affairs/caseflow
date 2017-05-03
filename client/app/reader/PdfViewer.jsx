import React, { PropTypes } from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';

import PdfUI from '../components/PdfUI';
import PdfSidebar from '../components/PdfSidebar';
import { documentPath } from './DecisionReviewer';
import Modal from '../components/Modal';
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

  onCommentChange = (documentId = this.selectedDocId()) => {
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
        this.selectedDocId(),
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
    if (comment) {
      this.props.annotationStorage.getAnnotation(
        this.selectedDocId(),
        this.state.editingComment
      ).then((annotation) => {
        annotation.comment = comment;
        this.props.annotationStorage.editAnnotation(
          this.selectedDocId(),
          annotation.uuid,
          annotation
        );
      });
    } else {
      this.onDeleteComment(this.state.editingComment);
    }
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
    if (content) {
      annotation.comment = content;
      this.props.annotationStorage.addAnnotation(
        this.selectedDocId(),
        pageNumber,
        annotation
      ).then((savedAnnotation) => {
        this.props.handleSelectCommentIcon(savedAnnotation);
      });
    }
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
      this.selectedDocId(),
      uuid
    ).then((annotation) => {
      annotation.x = coordinates.x;
      annotation.y = coordinates.y;
      annotation.page = page;
      this.props.annotationStorage.editAnnotation(
        this.selectedDocId(),
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
      if (event.key === 'ArrowLeft' && this.previousDocId()) {
        this.props.showPdf(this.previousDocId())();
      }
      if (event.key === 'ArrowRight' && this.nextDocId()) {
        this.props.showPdf(this.nextDocId())();
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
    if (nextProps.selectedDocId !== this.props.selectedDocId) {
      this.onCommentChange(nextProps.selectedDocId);
    }

    const nextDocId = Number(nextProps.match.params.docId);

    // Sync react-router with Redux's selectedDocid
    if (nextDocId !== nextProps.selectedDocId) {
      this.props.handleSelectCurrentPdf(nextDocId);
    }

    if (nextProps.scrollToComment &&
        nextProps.scrollToComment !== this.props.scrollToComment) {
      this.onCommentClick(nextProps.scrollToComment.id);
    }
  }

  selectedDocIndex = () => (
    _.findIndex(this.props.documents, { id: this.props.selectedDocId })
  )

  selectedDoc = () => (
    this.props.documents[this.selectedDocIndex()]
  )

  selectedDocId = () => this.props.selectedDocId

  previousDocId = () => {
    const previousDocExists = this.selectedDocIndex() > 0;

    if (previousDocExists) {
      return this.props.documents[this.selectedDocIndex() - 1].id;
    }
  }

  nextDocId = () => {
    const selectedDocIndex = this.selectedDocIndex();
    const nextDocExists = selectedDocIndex + 1 < _.size(this.props.documents);

    if (nextDocExists) {
      return this.props.documents[selectedDocIndex + 1].id;
    }
  }

  showDocumentsListNavigation = () => this.props.allDocuments.length > 1;

  render() {
    const doc = this.selectedDoc();

    // If we don't have a currently selected document, we
    // shouldn't render anything. On the next tick we dispatch
    // the action to redux that populates the documents and then we
    // render
    // TODO(jd): We should refactor and potentially create the store
    // with the documents already added
    if (!doc) {
      return null;
    }

    return (
      <div>
        <div className="cf-pdf-page-container">
          <PdfUI
            comments={this.state.comments}
            doc={doc}
            file={documentPath(this.props.selectedDocId)}
            pdfWorker={this.props.pdfWorker}
            id="pdf"
            documentPathBase={this.props.documentPathBase}
            onPageClick={this.placeComment}
            onShowList={this.props.onShowList}
            prevDocId={this.previousDocId()}
            nextDocId={this.nextDocId()}
            showPdf={this.props.showPdf}
            showDocumentsListNavigation={this.showDocumentsListNavigation()}
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
            doc={doc}
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
    hidePdfSidebar: state.ui.pdf.hidePdfSidebar,
    selectedDocId: state.ui.pdf.currentRenderedFile
  };
};
const mapDispatchToProps = (dispatch) => ({
  handlePlaceComment: () => dispatch(handlePlaceComment()),
  handleWriteComment: () => dispatch(handleWriteComment()),
  handleClearCommentState: () => dispatch(handleClearCommentState()),
  handleSelectCommentIcon: (comment) => dispatch(handleSelectCommentIcon(comment)),
  handleSelectCurrentPdf: (docId) => dispatch(selectCurrentPdf(docId))
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfViewer);

PdfViewer.propTypes = {
  annotationStorage: PropTypes.object,
  doc: PropTypes.object,
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
  documents: PropTypes.array.isRequired,
  allDocuments: PropTypes.array.isRequired,
  selectCurrentPdf: PropTypes.func,
  hidePdfSidebar: PropTypes.bool
};
