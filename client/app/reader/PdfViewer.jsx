import React, { PropTypes } from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { getAnnotationByDocumentId } from './util/AnnotationUtil';

import PdfUI from '../components/PdfUI';
import PdfSidebar from '../components/PdfSidebar';
import { documentPath } from './DecisionReviewer';
import Modal from '../components/Modal';
import { closeAnnotationDeleteModal, deleteAnnotation,
  stopPlacingAnnotation, handleSelectCommentIcon, selectCurrentPdf } from '../reader/actions';
import { bindActionCreators } from 'redux';

// PdfViewer is a smart component that renders the entire
// PDF view of the Reader SPA. It displays the PDF with UI
// as well as the sidebar for comments and document information.
export class PdfViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      comments: [],
      editingComment: null,
      onSaveCommentAdd: null
    };

    this.props.annotationStorage.setOnCommentChange(this.onCommentChange);
  }

  onCommentChange = (documentId = this.selectedDocId()) => {
    this.setState({
      comments: [...this.props.annotationStorage.getAnnotationByDocumentId(documentId)]
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
    this.onCancelCommentEdit();
  }

  onCancelCommentEdit = () => {
    this.setState({
      editingComment: null
    });
  }

  onSaveCommentAdd = (annotation, pageNumber) => (content) => {
    annotation.comment = content;
    this.props.annotationStorage.addAnnotation(
      this.selectedDocId(),
      pageNumber,
      annotation
    ).then((savedAnnotation) => {
      this.props.handleSelectCommentIcon(savedAnnotation);
    });
    this.props.stopPlacingAnnotation();
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
    if (this.props.placedButUnsavedAnnotation) {
      let commentBox = document.getElementById('addComment');

      commentBox.focus();
    }
  }

  componentDidMount = () => {
    this.onCommentChange();
    this.props.handleSelectCurrentPdf(this.selectedDocId());

    window.addEventListener('keydown', this.keyListener);
  }

  componentWillUnmount = () => {
    window.removeEventListener('keydown', this.keyListener);
  }

  componentWillReceiveProps = (nextProps) => {
    const nextDocId = Number(nextProps.match.params.docId);

    if (nextDocId !== this.selectedDocId()) {
      this.onCommentChange(nextDocId);
      this.props.handleSelectCurrentPdf(nextDocId);
    }

    if (nextProps.scrollToComment &&
        nextProps.scrollToComment !== this.props.scrollToComment) {
      this.onCommentClick(nextProps.scrollToComment.id);
    }
  }

  selectedDocIndex = () => (
    _.findIndex(this.props.documents, { id: this.selectedDocId() })
  )

  selectedDoc = () => (
    this.props.documents[this.selectedDocIndex()]
  )

  selectedDocId = () => Number(this.props.match.params.docId)

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
            comments={this.props.annotations}
            doc={doc}
            file={documentPath(this.selectedDocId())}
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
            onSaveCommentAdd={this.state.onSaveCommentAdd}
            onCancelCommentAdd={this.props.stopPlacingAnnotation}
            onSaveCommentEdit={this.onSaveCommentEdit}
            onCancelCommentEdit={this.onCancelCommentEdit}
            onEditComment={this.onEditComment}
            onJumpToComment={this.props.onJumpToComment}
          />
        </div>
        {this.props.deleteAnnotationModalIsOpenFor && <Modal
          buttons={[
            { classNames: ['cf-modal-link', 'cf-btn-link'],
              name: 'Cancel',
              onClick: this.props.closeAnnotationDeleteModal
            },
            { classNames: ['usa-button', 'usa-button-secondary'],
              name: 'Confirm delete',
              onClick: () => this.props.deleteAnnotation(
                this.props.match.params.docId,
                this.props.deleteAnnotationModalIsOpenFor
              )
            }
          ]}
          closeHandler={this.props.closeAnnotationDeleteModal}
          title="Delete Comment">
          Are you sure you want to delete this comment?
        </Modal>}
      </div>
    );
  }
}

const mapStateToProps = (state, ownProps) => ({
  annotations: getAnnotationByDocumentId(state.annotations, ownProps.match.params.docId),
  ..._.pick(state.ui, 'deleteAnnotationModalIsOpenFor', 'placedButUnsavedAnnotation'),
  ..._.pick(state.ui.pdf, 'commentFlowState', 'scrollToComment', 'hidePdfSidebar')
});
const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    closeAnnotationDeleteModal,
    deleteAnnotation,
    stopPlacingAnnotation
  }, dispatch),

  handleSelectCommentIcon: (comment) => dispatch(handleSelectCommentIcon(comment)),
  handleSelectCurrentPdf: (docId) => dispatch(selectCurrentPdf(docId))
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfViewer);

PdfViewer.propTypes = {
  annotationStorage: PropTypes.object,
  annotations: PropTypes.arrayOf(PropTypes.object),
  doc: PropTypes.object,
  pdfWorker: PropTypes.string,
  scrollToComment: PropTypes.shape({
    id: React.PropTypes.number
  }),
  deleteAnnotationModalIsOpenFor: PropTypes.number,
  onScrollToComment: PropTypes.func,
  onCommentScrolledTo: PropTypes.func,
  handleSelectCommentIcon: PropTypes.func,
  documents: PropTypes.array.isRequired,
  allDocuments: PropTypes.array.isRequired,
  selectCurrentPdf: PropTypes.func,
  hidePdfSidebar: PropTypes.bool
};
