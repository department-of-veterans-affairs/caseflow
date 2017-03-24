import React, { PropTypes } from 'react';
import PDFJSAnnotate from 'pdf-annotate.js';
import PdfUI from '../components/PdfUI';
import PdfSidebar from '../components/PdfSidebar';
import FormField from '../util/FormField';
import BaseForm from '../containers/BaseForm';
import TextareaField from '../components/TextareaField';

// PdfViewer is a smart component that renders the entire
// PDF view of the Reader SPA. It displays the PDF with UI
// as well as the sidebar for comments and document information.
export default class PdfViewer extends BaseForm {
  constructor(props) {
    super(props);
    this.state = {
      commentBoxEventListener: null,
      commentOverIndex: null,
      comments: [],
      currentPage: 1,
      editingComment: null,
      isAddingComment: false,
      isPlacingNote: false,
      numPages: 0,
      scale: 1,
      onSaveComment: null
    };

    this.props.annotationStorage.setOnCommentChange(this.onCommentChange);
  }

  onCommentChange = (documentId = this.props.doc.id) => {
    this.setState({ comments: [...this.props.annotationStorage.getAnnotationByDocumentId(documentId)] });
  }

  onDeleteComment = (uuid) => {
    this.props.annotationStorage.deleteAnnotation(
      this.props.doc.id,
      uuid
    );
  }

  // TODO: refactor this method to make it cleaner
  onSaveCommentEdit = (comment, uuid)  => {
    this.props.annotationStorage.getAnnotation(
      this.props.doc.id,
      uuid,
    ).then((annotation) => {
      annotation.comment = comment;
      this.props.annotationStorage.editAnnotation(
        this.props.doc.id,
        annotation.uuid,
        annotation
      );
    });
  }

  onAddComment = () => {
    this.setState({
      isPlacingNote: true
    });
  }

  onAddCommentComplete = () => {
    this.setState({
      isAddingComment: false,
      isPlacingNote: false,
      onSaveComment: null
    });
  }

  onSaveComment = (annotation, pageNumber) => (content) => {
    annotation.comment = content;
    this.props.annotationStorage.addAnnotation(
      this.props.doc.id,
      pageNumber,
      annotation
    );
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
        onSaveComment: this.onSaveComment(annotation, pageNumber)
      });
    }
  }

  // Returns true if the user is doing some action. i.e.
  // editing a note, adding a note, or placing a comment.
  isUserActive = () => this.state.editingComment !== null ||
      this.state.isAddingComment ||
      this.state.isPlacingNote

  keyListener = (event) => {
    if (!this.isUserActive()) {
      if (event.key === 'ArrowLeft') {
        this.props.previousPdf();
      }
      if (event.key === 'ArrowRight') {
        this.props.nextPdf();
      }
    }
  }

  componentDidMount = () => {
    const { UI } = PDFJSAnnotate;

    this.onCommentChange();

    UI.addEventListener('annotation:click', (event) => {
      let comments = [...this.state.comments];

      comments = comments.map((comment) => {
        let copy = { ...comment };

        copy.selected = false;
        if (comment.uuid.toString() ===
            event.getAttribute('data-pdf-annotate-id').toString()) {
          copy.selected = true;
        }

        return copy;
      });
      this.setState({ comments });

    });

    window.addEventListener('keydown', this.keyListener);

    UI.enableEdit();
  }

  componentWillUnmount = () => {
    window.removeEventListener('keydown', this.keyListener);
  }

  componentDidUpdate = () => {
    if (this.state.isAddingComment) {
      let commentBox = document.getElementById('addComment');

      commentBox.focus();
    }
  }

  componentWillReceiveProps = (nextProps) => {
    if (nextProps.doc.id !== this.props.doc.id) {
      this.onCommentChange(nextProps.doc.id);
    }
  }

  onJumpToComment = (uuid) => () => {
    PDFJSAnnotate.
      getStoreAdapter().
      getAnnotation(this.props.doc.id, uuid).
      then((annotation) => {
        let page = document.getElementsByClassName('page');
        let scrollWindow = document.getElementById('scrollWindow');

        scrollWindow.scrollTop =
          page[annotation.page - 1].getBoundingClientRect().top +
          annotation.y - 100 + scrollWindow.scrollTop;
      });
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
            id="pdf1"
            label={this.props.label}
            onPageClick={this.placeComment}
            onSetLabel={this.props.onSetLabel}
            onShowList={this.props.onShowList}
            onNextPdf={this.props.onNextPdf}
            onPreviousPdf={this.props.onPreviousPdf}
            onViewPortCreated={this.onViewPortCreated}
            onViewPortsCleared={this.onViewPortsCleared}
          />
          <PdfSidebar
            doc={this.props.doc}
            onAddComment={this.onAddComment}
            isAddingComment={this.state.isAddingComment}
            comments={this.state.comments}
            onSaveComment={this.state.onSaveComment}
            onSaveCommentEdit={this.onSaveCommentEdit}
            onAddCommentComplete={this.onAddCommentComplete}
            onDeleteComment={this.onDeleteComment}
            onJumpToComment={this.onJumpToComment}
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
  onSetLabel: PropTypes.func.isRequired
};
