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
      commentForm: {
        editComment: new FormField('')
      },
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
    this.comments = [];

    this.setState({ comments: this.comments });
    this.props.annotationStorage.getAnnotationByDocumentId(documentId).
      forEach((annotation) => {
        this.comments.push({
          content: annotation.comment,
          uuid: annotation.uuid
        });
        this.setState({ comments: this.comments });
      });
  }

  showEditIcon = (index) => () => {
    this.setState({
      commentOverIndex: index
    });
  }

  hideEditIcon = (index) => () => {
    if (this.state.commentOverIndex === index) {
      this.setState({
        commentOverIndex: null
      });
    }
  }

  editComment = (index) => () => {
    let commentForm = { ...this.state.commentForm };

    commentForm.editComment.value = this.state.comments[index].content;
    this.setState({
      commentForm,
      editingComment: index
    });
  }

  // TODO: refactor this method to make it cleaner
  saveEdit = (comment) => (event) => {
    if (event.key === 'Enter') {
      let commentToAdd = this.state.commentForm.editComment.value;

      this.props.annotationStorage.getAnnotation(
        this.props.doc.id,
        comment.uuid,
      ).then((annotation) => {
        annotation.comment = commentToAdd;
        this.props.annotationStorage.editAnnotation(
          this.props.doc.id,
          annotation.uuid,
          annotation
        ).
        catch(() => {
          // TODO: Add error case if comment can't be added
          /* eslint-disable no-console */
          console.log('Error editing annotation in saveEdit');

          /* eslint-enable no-console */
        });
      }).
      catch(() => {

        /* eslint-disable no-console */
        console.log('Error getting annotation in saveEdit');

        /* eslint-enable no-console */
      });

      this.setState({
        editingComment: null
      });
    }
    if (event.key === 'Escape') {
      this.setState({
        editingComment: null
      });
    }
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

  onSaveComment = (annotation, viewport, pageNumber) => (content) => {
    annotation.comment = content;
    this.props.annotationStorage.addAnnotation(
        this.props.doc.id,
        pageNumber,
        annotation
      ).then(() => {
        this.props.annotationStorage.getAnnotations(this.props.doc.id, pageNumber).
          then((annotations) => {
            // Redraw all the annotations on the page to show the new one.
            let svg = document.getElementById(`pageContainer${pageNumber}`).
              getElementsByClassName("annotationLayer")[0];

            // This is the icky part of this component. We have to
            // hook directly into PDFJSAnnotate to trigger a redraw
            // of the page, in order to see the new comments
            PDFJSAnnotate.render(svg, viewport, annotations);
          });
      });
  }

  placeComment = (viewport, pageNumber, coordinates) => {
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
        onSaveComment: this.onSaveComment(annotation, viewport, pageNumber)
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

  onCommentClick = (event) => {
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
  }

  componentDidMount = () => {
    const { UI } = PDFJSAnnotate;

    this.onCommentChange();

    UI.addEventListener('annotation:click', this.onCommentClick);

    window.addEventListener('keydown', this.keyListener);

    UI.enableEdit();
  }

  componentWillUnmount = () => {
    const { UI } = PDFJSAnnotate;

    UI.removeEventListener('annotation:click', this.onCommentClick);
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

  scrollToAnnotation = (uuid) => () => {
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
    let comments = [];

    comments = this.state.comments.map((comment, index) => {
      let selectedClass = comment.selected ? " cf-comment-selected" : "";

      if (this.state.editingComment === index) {
        return (
          <div
            key="commentEditor"
            className="cf-pdf-comment-list-item"
            onKeyUp={this.saveEdit(comment)}>
            <TextareaField
              label="Edit Comment"
              name="editComment"
              onChange={this.handleFieldChange('commentForm', 'editComment')}
              {...this.state.commentForm.editComment}
            />
          </div>);
      }

      return <div
          onClick={this.scrollToAnnotation(comment.uuid)}
          onMouseEnter={this.showEditIcon(index)}
          onMouseLeave={this.hideEditIcon(index)}
          className={`cf-pdf-comment-list-item${selectedClass}`}
          key={`comment${index}`}
          id={`comment${index}`}>
          {this.state.commentOverIndex === index &&
            <div className="cf-pdf-edit-comment" onClick={this.editComment(index)}>
              <i
                className="cf-pdf-edit-comment-icon fa fa-pencil"
                aria-hidden="true"></i>
            </div>}
          {comment.content}
        </div>;
    });

    return (
      <div>
        <div className="cf-pdf-page-container">
          <PdfUI
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
          />
          <PdfSidebar
            doc={this.props.doc}
            onAddComment={this.onAddComment}
            isAddingComment={this.state.isAddingComment}
            comments={comments}
            onSaveComment={this.state.onSaveComment}
            onAddCommentComplete={this.onAddCommentComplete}
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
