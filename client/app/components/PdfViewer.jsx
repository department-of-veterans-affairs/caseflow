/* eslint-disable max-lines */
import React, { PropTypes } from 'react';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import PDFJSAnnotate from 'pdf-annotate.js';
import Button from '../components/Button';
import { formatDate } from '../util/DateUtil';
import TextareaField from '../components/TextareaField';
import FormField from '../util/FormField';
import BaseForm from '../containers/BaseForm';

/* eslint-disable no-bitwise */
/* eslint-disable no-mixed-operators */
/* From http://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript */
let generateUUID = function() {
  let date = new Date().getTime();
  let uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (character) => {
    let random = (date + Math.random() * 16) % 16 | 0;

    date = Math.floor(date / 16);

    return (character === 'x' ? random : random & 0x3 | 0x8).toString(16);
  });

  return uuid;
};

/* eslint-enable no-bitwise */
/* eslint-enable no-mixed-operators */

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
  }

  generateComments = (pdfDocument) => {
    this.comments = [];
    let storeAdapter = PDFJSAnnotate.getStoreAdapter();

    this.setState({ comments: this.comments });
    for (let i = 1; i <= pdfDocument.pdfInfo.numPages; i++) {
      storeAdapter.getAnnotations(this.props.file, i).then((annotations) => {
        annotations.annotations.forEach((annotationId) => {
          storeAdapter.getComments(this.props.file, annotationId.uuid).
            then((comment) => {
              if (comment.length) {
                this.comments.push({
                  annotationUuid: annotationId.uuid,
                  commentUuid: comment[0].uuid,
                  content: comment[0].content
                });
                this.setState({ comments: this.comments });
              }
            });
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
  saveEdit = (comment) => {
    let storeAdapter = PDFJSAnnotate.getStoreAdapter();

    return (event) => {
      if (event.key === 'Enter') {
        let commentToAdd = this.state.commentForm.editComment.value;

        storeAdapter.deleteComment(
          this.props.file,
          comment.commentUuid
        ).then(() => {
          storeAdapter.addComment(
            this.props.file,
            comment.annotationUuid,
            commentToAdd
          ).then(() => {
            this.generateComments(this.state.pdfDocument);
          }).
          catch(() => {
            // TODO: Add error case if comment can't be added
          });
        }).
        catch(() => {
          // TODO: Add error case if comment can't be added
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
    };
  }

  addEventListners = (pdfDocument) => {
    const { UI } = PDFJSAnnotate;

    this.removeEventListeners();

    this.annotationAddListener = () => {
      this.generateComments(pdfDocument);
    };
    UI.addEventListener('annotation:add', this.annotationAddListener);
  }

  removeEventListeners = () => {
    const { UI } = PDFJSAnnotate;

    if (this.annotationAddListener) {
      UI.removeEventListener('annotation:add', this.annotationAddListener);
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

  placeNote = (viewport, pageNumber) => (event) => {
    if (this.state.isPlacingNote) {
      let annotation = {
        class: "Annotation",
        page: pageNumber,
        "type": "point",
        uuid: generateUUID(),
        "x": (event.offsetX + event.srcElement.offsetLeft) / this.state.scale,
        "y": (event.offsetY + event.srcElement.offsetTop) / this.state.scale
      };
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

  saveNote = (annotation, viewport, pageNumber) => {
    let storeAdapter = PDFJSAnnotate.getStoreAdapter();


    return (content) => {
      storeAdapter.addAnnotation(
        this.props.file,
        pageNumber,
        annotation
      ).then((returnedAnnotation) => {
        storeAdapter.getAnnotations(this.props.file, pageNumber).then((annotations) => {
          storeAdapter.addComment(
            this.props.file,
            returnedAnnotation.uuid,
            content
          ).then(() => {
            this.generateComments(this.state.pdfDocument);
          });
          // Redraw all the annotations on the page to show the new one.
          let svg = document.getElementById(`pageContainer${pageNumber}`).
            getElementsByClassName("annotationLayer")[0];

          PDFJSAnnotate.render(svg, viewport, annotations);
        });
      });
    };
  }

  renderPage = (index) => {
    const { UI } = PDFJSAnnotate;

    let RENDER_OPTIONS = {
      documentId: this.props.file,
      pdfDocument: this.state.pdfDocument,
      rotate: 0,
      scale: this.state.scale
    };

    this.isRendered[index] = true;
    UI.renderPage(index + 1, RENDER_OPTIONS).then(([pdfPage]) => {
      let pageContainer = document.getElementById(`pageContainer${index + 1}`);

      pageContainer.addEventListener('click',
        this.placeNote(pdfPage.getViewport(this.state.scale, 0), index + 1));
    }).
    catch(() => {
      this.isRendered[index] = false;
    });
  }

  createPages = (pdfDocument) => {
    const { UI } = PDFJSAnnotate;

    // Create a page in the DOM for every page in the PDF
    let viewer = document.getElementById('viewer');

    viewer.innerHTML = '';

    for (let i = 0; i < pdfDocument.pdfInfo.numPages; i++) {
      let page = UI.createPage(i + 1);

      viewer.appendChild(page);
    }
  }

  draw = (file, scrollLocation = 0) => {
    PDFJS.getDocument(file).then((pdfDocument) => {
      this.generateComments(pdfDocument);
      this.isRendered = new Array(pdfDocument.pdfInfo.numPages);
      this.setState({
        currentPage: 1,
        numPages: pdfDocument.pdfInfo.numPages,
        pdfDocument
      });

      this.createPages(pdfDocument);
      this.addEventListners(pdfDocument);

      // Automatically render the first page
      // This assumes that page has already been created and appended
      this.renderPage(0);
      document.getElementById('scrollWindow').scrollTop = scrollLocation;
      this.scrollEvent();
    });
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.file !== this.props.file) {
      document.getElementById('scrollWindow').scrollTop = 0;
      this.draw(nextProps.file);
    }
  }

  zoom = (delta) => () => {
    let zoomFactor = (this.state.scale + delta) / this.state.scale;

    this.setState({
      scale: this.state.scale + delta
    });
    this.draw(this.props.file,
      document.getElementById('scrollWindow').scrollTop * zoomFactor);
  }

  scrollEvent = () => {
    let page = document.getElementsByClassName('page');
    let scrollWindow = document.getElementById('scrollWindow');

    Array.prototype.forEach.call(page, (ele, index) => {
      let boundingRect = ele.getBoundingClientRect();

      // You are on this page, if the top of the page is above the middle
      // and the bottom of the page is below the middle
      if (boundingRect.top < scrollWindow.clientHeight / 2 &&
          boundingRect.bottom > scrollWindow.clientHeight / 2) {
        this.setState({
          currentPage: index + 1
        });
      }

      // This renders each page as it comes into view. i.e. when
      // the top of the next page is within a thousand pixels of
      // the current view we render it. If the bottom of the page
      // above is within a thousand pixels of the current view
      // we also redner it.
      // TODO: Make this more robust and avoid magic numbers.
      if (!this.isRendered[index] &&
          boundingRect.bottom > -1000 &&
          boundingRect.top < scrollWindow.clientHeight + 1000) {
        this.renderPage(index);
      }
    });
  }

  componentDidMount = () => {
    const { UI } = PDFJSAnnotate;

    PDFJS.workerSrc = '../assets/pdf.worker.js';
    PDFJSAnnotate.setStoreAdapter(new PDFJSAnnotate.LocalStoreAdapter());

    UI.addEventListener('annotation:click', (event) => {
      let comments = [...this.state.comments];

      comments = comments.map((comment) => {
        let copy = { ...comment };

        copy.selected = false;
        if (comment.annotationUuid === event.getAttribute('data-pdf-annotate-id')) {
          copy.selected = true;
        }

        return copy;
      });
      this.setState({ comments });

    });

    this.draw(this.props.file);

    // Scroll event to render pages as they come into view
    let scrollWindow = document.getElementById('scrollWindow');

    scrollWindow.addEventListener('scroll', this.scrollEvent);
    UI.enableEdit();
  }

  componentWillUnmount = () => {
    this.removeEventListeners();
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
      getAnnotation(this.props.file, uuid).
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
          onClick={this.scrollToAnnotation(comment.annotationUuid)}
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
          <div className="cf-pdf-container">
            <div className="cf-pdf-header cf-pdf-toolbar">
              <div className="usa-grid-full">
                <div className="usa-width-one-third cf-pdf-buttons-left">
                  {this.props.name}
                </div>
                <div className="usa-width-one-third cf-pdf-buttons-center">
                  {this.state.currentPage} / {this.state.numPages}
                </div>
                <div className="usa-width-one-third cf-pdf-buttons-right">
                  <Button
                    name="previous"
                    classNames={["cf-pdf-button"]}
                    onClick={this.props.previousPdf}>
                    <i className="fa fa-chevron-left" aria-hidden="true"></i>Previous
                  </Button>
                  <Button
                    name="next"
                    classNames={["cf-pdf-button"]}
                    onClick={this.props.nextPdf}>
                    Next<i className="fa fa-chevron-right" aria-hidden="true"></i>
                  </Button>
                </div>
              </div>
            </div>
            <div id="scrollWindow" className="cf-pdf-scroll-view">
              <div
                id="viewer"
                className={`${this.state.isPlacingNote ? "cf-comment-cursor " : ""}` +
                `cf-pdf-page pdfViewer singlePageView`}>
              </div>
            </div>
            <div className="cf-pdf-footer cf-pdf-toolbar">
              <div className="usa-grid-full">
                <div className="usa-width-one-third cf-pdf-buttons-left">
                  <Button
                    name="previous"
                    classNames={["cf-pdf-bookmarks cf-pdf-button"]}
                    onClick={this.zoom(-0.3)}>
                    <i
                      style={{ color: '#23ABF6' }}
                      className="fa fa-bookmark"
                      aria-hidden="true"></i>
                  </Button>
                  <Button
                    name="previous"
                    classNames={["cf-pdf-bookmarks cf-pdf-button"]}
                    onClick={this.zoom(-0.3)}>
                    <i
                      style={{ color: '#F6A623' }}
                      className="fa fa-bookmark"
                      aria-hidden="true"></i>
                  </Button>
                  <Button
                    name="previous"
                    classNames={["cf-pdf-bookmarks cf-pdf-button"]}
                    onClick={this.zoom(-0.3)}>
                    <i
                      style={{ color: '#FFFFFF' }}
                      className="fa fa-bookmark"
                      aria-hidden="true"></i>
                  </Button>
                  <Button
                    name="previous"
                    classNames={["cf-pdf-bookmarks cf-pdf-button"]}
                    onClick={this.zoom(-0.3)}>
                    <i
                      style={{ color: '#F772E7' }}
                      className="fa fa-bookmark"
                      aria-hidden="true"></i>
                  </Button>
                  <Button
                    name="previous"
                    classNames={["cf-pdf-bookmarks cf-pdf-button"]}
                    onClick={this.zoom(-0.3)}>
                    <i
                      style={{ color: '#3FCD65' }}
                      className="fa fa-bookmark"
                      aria-hidden="true"></i>
                  </Button>
                  <Button
                    name="previous"
                    classNames={["cf-pdf-bookmarks cf-pdf-button"]}
                    onClick={this.zoom(-0.3)}>
                    <i
                      style={{ color: '#EFDF1A' }}
                      className="fa fa-bookmark"
                      aria-hidden="true"></i>
                  </Button>
                </div>
                <div className="usa-width-one-third cf-pdf-buttons-center">
                  <Button
                    name="previous"
                    classNames={["cf-pdf-button"]}
                    onClick={this.zoom(-0.3)}>
                    <i className="fa fa-minus" aria-hidden="true"></i>
                  </Button>
                  <Button
                    name="fit"
                    classNames={["cf-pdf-button"]}
                    onClick={this.zoom(1)}>
                    <i className="cf-pdf-button fa fa-arrows-alt" aria-hidden="true"></i>
                  </Button>
                  <Button
                    name="previous"
                    classNames={["cf-pdf-button"]}
                    onClick={this.zoom(0.3)}>
                    <i className="fa fa-plus" aria-hidden="true"></i>
                  </Button>
                </div>
                <div className="usa-width-one-third cf-pdf-buttons-right">
                  <Button name="download" classNames={["cf-pdf-button"]}>
                    <i className="cf-pdf-button fa fa-download" aria-hidden="true"></i>
                  </Button>
                  <Button name="print" classNames={["cf-pdf-button"]}>
                    <i className="cf-pdf-button fa fa-print" aria-hidden="true"></i>
                  </Button>
                </div>
              </div>
            </div>
          </div>
          <div className="cf-sidebar-wrapper">
            <div className="cf-document-info-wrapper">
              <div className="cf-heading-alt">Document</div>
              <p className="cf-pdf-meta-title"><b>Filename:</b> {this.props.name}</p>
              <p className="cf-pdf-meta-title"><b>Document Type:</b> {this.props.type}</p>
              <p className="cf-pdf-meta-title"><b>Receipt Date:</b> {formatDate(this.props.receivedAt)}</p>
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
  file: PropTypes.string.isRequired
};

/* eslint-enable max-lines */
