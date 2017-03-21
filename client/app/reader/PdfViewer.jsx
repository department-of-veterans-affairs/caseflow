/* eslint-disable max-lines */
import React, { PropTypes } from 'react';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import PDFJSAnnotate from 'pdf-annotate.js';
import Button from '../components/Button';
import { formatDate } from '../util/DateUtil';
import TextareaField from '../components/TextareaField';
import FormField from '../util/FormField';
import BaseForm from '../containers/BaseForm';
import DocumentLabels from '../components/DocumentLabels';
import PdfUI from '../components/PdfUI';

export const linkToSingleDocumentView = (doc) => {
  let id = doc.id;
  let filename = doc.filename;
  let type = doc.type;
  let receivedAt = doc.received_at;

  return `/decision/review/show?id=${id}&type=${type}` +
    `&received_at=${receivedAt}&filename=${filename}`;
};


export default class PdfViewer extends BaseForm {
  constructor(props) {
    super(props);
    this.state = {
      commentBoxEventListener: null,
      commentForm: {
        addComment: new FormField(''),
        editComment: new FormField('')
      },
      commentOverIndex: null,
      comments: [],
      currentPage: 1,
      editingComment: null,
      isAddingComment: false,
      isPlacingNote: false,
      numPages: 0,
      scale: 1
    };

    this.props.annotationStorage.setOnCommentChange(this.onCommentChange);
  }

  onCommentChange = () => {
    this.comments = [];

    this.setState({ comments: this.comments });
    // TODO: Change the interface in which we query all the comments.
    for (let i = 1; i <= this.state.numPages; i++) {
      this.props.annotationStorage.getAnnotations(this.props.doc.id, i).
        then((annotations) => {
          annotations.annotations.sort((first, second) => {
            return first.y - second.y;
          }).forEach((annotation) => {
            this.comments.push({
              content: annotation.comment,
              uuid: annotation.uuid
            });
            this.setState({ comments: this.comments });
          });
        });
    }
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

  addNote = () => {
    this.setState({
      isPlacingNote: true
    });
  }

  commentKeyPress = (saveNote) => (event) => {
    let commentForm = { ...this.state.commentForm };
    // TODO: Should we continue to save on blur?

    if (event.type === 'blur' || event.key === 'Enter') {
      if (this.state.commentForm.addComment.value.length > 0) {
        saveNote(this.state.commentForm.addComment.value);
      }
      commentForm.addComment.value = '';
      this.setState({
        commentForm,
        isAddingComment: false
      });
    }
    if (event.key === 'Escape') {
      commentForm.addComment.value = '';
      this.setState({
        commentForm,
        isAddingComment: false
      });
    }
  }

  saveNote = (annotation, viewport, pageNumber) => (content) => {
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

            PDFJSAnnotate.render(svg, viewport, annotations);
          });
      });
  }




  placeNote = (viewport, pageNumber, annotation) => {   
    if (this.state.isPlacingNote) {   
      let commentBox = document.getElementById('addComment');   
      let commentEvent = this.commentKeyPress(    
        this.saveNote(annotation, viewport, pageNumber));   
    
      if (this.state.commentBoxEventListener) {   
        commentBox.removeEventListener("keyup", this.state.commentBoxEventListener);    
        commentBox.removeEventListener("blur", this.state.commentBoxEventListener);   
      }

      commentBox.addEventListener('keyup', commentEvent);    
      commentBox.addEventListener('blur', commentEvent);    
      this.setState({   
        commentBoxEventListener: commentEvent,    
        isAddingComment: true,    
        isPlacingNote: false    
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
            onPageClick={this.placeNote}
          />
          <div className="cf-sidebar-wrapper">
            <div className="cf-document-info-wrapper">
              <div className="cf-heading-alt">Document</div>
              <p className="cf-pdf-meta-title">
                <b>Filename:</b> {this.props.doc.filename}
              </p>
              <p className="cf-pdf-meta-title">
                <b>Document Type:</b> {this.props.doc.type}
              </p>
              <p className="cf-pdf-meta-title">
                <b>Receipt Date:</b> {formatDate(this.props.doc.received_at)}
              </p>
              <div className="cf-heading-alt">
                Notes
                <span className="cf-right-side">
                  <a onClick={this.addNote}>+ Add a Note</a>
                </span>
              </div>
            </div>

            <div className="cf-comment-wrapper">
              <div className="cf-pdf-comment-list">
                <div
                  className="cf-pdf-comment-list-item"
                  hidden={!this.state.isAddingComment}>
                  <TextareaField
                    label="Add Comment"
                    name="addComment"
                    onChange={this.handleFieldChange('commentForm', 'addComment')}
                    {...this.state.commentForm.addComment}
                  />
                </div>
                {comments}
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

PdfViewer.propTypes = {
  annotationStorage: PropTypes.object,
  doc: PropTypes.object,
  file: PropTypes.string.isRequired,
  hideNavigation: PropTypes.bool,
  label: PropTypes.string,
  pdfWorker: PropTypes.string,
  setLabel: PropTypes.func.isRequired
};

/* eslint-enable max-lines */
