import React, { PropTypes } from 'react';
import PDFJSAnnotate from 'pdf-annotate.js';
import PdfUI from '../components/PdfUI';
import PdfSidebar from '../components/PdfSidebar';

// PdfViewer is a smart component that renders the entire
// PDF view of the Reader SPA. It displays the PDF with UI
// as well as the sidebar for comments and document information.
export default class PdfViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      comments: [],
      editingComment: null,
      isAddingComment: false,
      isPlacingNote: false,
      onSaveCommentAdd: null
    };

    this.props.annotationStorage.setOnCommentChange(this.onCommentChange);
  }

  onCommentChange = (documentId = this.props.doc.id) => {
    this.setState({
      comments: [...this.props.annotationStorage.getAnnotationByDocumentId(documentId)]
    });
  }

  onDeleteComment = (uuid) => {
    this.props.annotationStorage.deleteAnnotation(
      this.props.doc.id,
      uuid
    );
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
      this.state.editingComment,
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
      this.setState({
        isPlacingNote: true
      });
    }
  }

  placeComment = (pageNumber, coordinates) => {
    if (this.state.isPlacingNote) {
      let annotation = {
        class: "Annotation",
        page: pageNumber,
        "type": "point",
        "x": coordinates.xPosition,
        "y": coordinates.yPosition
      };

      this.setState({
        isAddingComment: true,
        isPlacingNote: false,
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
    );
    this.onCancelCommentAdd();
  }

  onCancelCommentAdd = () => {
    this.setState({
      isAddingComment: false,
      isPlacingNote: false,
      onSaveCommentAdd: null
    });
  }

  // Returns true if the user is doing some action. i.e.
  // editing a note, adding a note, or placing a comment.
  isUserActive = () => this.state.editingComment !== null ||
      this.state.isAddingComment ||
      this.state.isPlacingNote

  keyListener = (event) => {
    if (!this.isUserActive()) {
      if (event.key === 'ArrowLeft') {
        this.props.onPreviousPdf();
      }
      if (event.key === 'ArrowRight') {
        this.props.onNextPdf();
      }
    }
  }

  onCommentClick = (clickedComment) => {
    let comments = [...this.state.comments].map((comment) => {
      if (clickedComment.uuid === comment.uuid) {
        comment.selected = true;
      } else {
        comment.selected = false;
      }

      return comment;
    });

    this.setState({ comments });
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
            label={this.props.label}
            onPageClick={this.placeComment}
            onSetLabel={this.props.onSetLabel}
            onShowList={this.props.onShowList}
            onNextPdf={this.props.onNextPdf}
            onPreviousPdf={this.props.onPreviousPdf}
            onViewPortCreated={this.onViewPortCreated}
            onViewPortsCleared={this.onViewPortsCleared}
            onCommentClick={this.onCommentClick}
            scrollToComment={this.props.scrollToComment}
          />
          <PdfSidebar
            doc={this.props.doc}
            editingComment={this.state.editingComment}
            onAddComment={this.onAddComment}
            isAddingComment={this.state.isAddingComment}
            comments={this.state.comments}
            onSaveCommentAdd={this.state.onSaveCommentAdd}
            onCancelCommentAdd={this.onCancelCommentAdd}
            onSaveCommentEdit={this.onSaveCommentEdit}
            onCancelCommentEdit={this.onCancelCommentEdit}
            onDeleteComment={this.onDeleteComment}
            onEditComment={this.onEditComment}
            onScrollToComment={this.props.onScrollToComment}
          />
        </div>
      </div>
    );
  }
}

PdfViewer.propTypes = {
  annotationStorage: PropTypes.object,
  doc: PropTypes.object,
  file: PropTypes.string.isRequired,
  label: PropTypes.string,
  pdfWorker: PropTypes.string,
  onSetLabel: PropTypes.func.isRequired,
  scrollToComment: PropTypes.number
};
