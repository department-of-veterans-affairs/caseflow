import React, { PropTypes } from 'react';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import PDFJSAnnotate from 'pdf-annotate.js';
import appendChild from 'pdf-annotate.js';
import DateSelector from '../components/DateSelector';
import DropDown from '../components/DropDown';
import Button from '../components/Button';
import TextareaField from '../components/TextareaField';
import FormField from '../util/FormField';
import BaseForm from '../containers/BaseForm';

export default class PdfViewer extends BaseForm {
  constructor(props) {
    super(props);
    this.state = {
      commentForm: {
        addComment: new FormField('')
      },
      isAddingComment: false,
      isPlacingNote: false,
      comments: [],
      currentPage: 1,
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
                  content: comment[0].content,
                  uuid: annotationId.uuid
                });
                this.setState({ comments: this.comments });
              }
            });
        });
      });
    }
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

  generateUUID() {
    var d = new Date().getTime();
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = (d + Math.random()*16)%16 | 0;
      d = Math.floor(d/16);
      return (c=='x' ? r : (r&0x3|0x8)).toString(16);
    });
    return uuid;
  };

  addNote = () => {
    this.setState({
      isPlacingNote: true
    });
  }

  commentKeyPress = (saveNote) => {
    return (event) => {
      debugger;
      if(event.type === 'blur' || event.key === 'Enter') {
        if (this.state.commentForm.addComment.value.length > 0) {
          saveNote(this.state.commentForm.addComment.value);  
        }
        this.setState({
          isAddingComment: false,
          commentForm: {addComment: {value: ''}}
        });
      }
      if (event.key === 'Escape') {
        this.setState({
          isAddingComment: false
        });
      }
    }
  }

  placeNote = (viewport, pageNumber) => {
    return (event) => {
      if (this.state.isPlacingNote) {
        this.setState({
          isPlacingNote: false,
          isAddingComment: true
        });

        let annotation = {
          "type": "point",
          "x": event.offsetX/this.state.scale,
          "y": event.offsetY/this.state.scale,
          class: "Annotation",
          uuid: this.generateUUID(),
          page: pageNumber
        }
        let commentBox = document.getElementById('addComment');
        let commentEvent = this.commentKeyPress(this.saveNote(annotation, viewport, pageNumber));
        commentBox.addEventListener('keyup', commentEvent);
        commentBox.focus();
        commentBox.addEventListener('blur', commentEvent);
      }
    }
  }

  saveNote = (annotation, viewport, pageNumber) => {
    let storeAdapter = PDFJSAnnotate.getStoreAdapter();
    return (content) => {
      storeAdapter.addAnnotation(
        this.props.file,
        pageNumber,
        annotation
      ).then((annotation) => {
        storeAdapter.getAnnotations(this.props.file, pageNumber).then((annotations) => {
          storeAdapter.addComment(
            this.props.file,
            annotation.uuid,
            content
          ).then(() => {
            this.generateComments(this.state.pdfDocument);
          });
          let svg = document.getElementById('pageContainer'+(pageNumber)).getElementsByClassName("annotationLayer")[0];
          PDFJSAnnotate.render(svg, viewport, annotations);
        });
      });
    }
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
      let pageContainer = document.getElementById('pageContainer'+(index+1));
      console.log(pageContainer);
      pageContainer.addEventListener('click', this.placeNote(pdfPage.getViewport(this.state.scale, 0), index + 1));
    }).catch(() => {
      this.isRendered[index] = false;
    });
  }

  draw = (file, scrollLocation = 0) => {
    const { UI } = PDFJSAnnotate;

    PDFJS.getDocument(file).then((pdfDocument) => {
      this.generateComments(pdfDocument);
      this.isRendered = new Array(pdfDocument.pdfInfo.numPages);

      this.setState({
        currentPage: 1,
        numPages: pdfDocument.pdfInfo.numPages,
        pdfDocument: pdfDocument
      });

      // Create a page in the DOM for every page in the PDF
      let viewer = document.getElementById('viewer');

      viewer.innerHTML = '';

      for (let i = 0; i < pdfDocument.pdfInfo.numPages; i++) {
        let page = UI.createPage(i + 1);

        viewer.appendChild(page);
      }
      this.addEventListners(pdfDocument);

      // Automatically render the first page
      // This assumes that page has already been created and appended
      this.renderPage(0);
      document.getElementById('scrollWindow').scrollTop = scrollLocation;
      console.log("scrollLocation: " + scrollLocation);
      console.log(this.state.scale);
      this.scrollEvent();
    });
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.file !== this.props.file) {
      document.getElementById('scrollWindow').scrollTop = 0;
      this.draw(nextProps.file);
    }
  }

  zoom = (delta) => {
    return () => {
      let zoomFactor = (this.state.scale + delta) / this.state.scale;
      this.setState({
        scale: this.state.scale + delta
      });
      this.draw(this.props.file, document.getElementById('scrollWindow').scrollTop * zoomFactor);
    }
  }

  scrollEvent = () => {
    let page = document.getElementsByClassName('page');

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

    PDFJSAnnotate.setStoreAdapter(new PDFJSAnnotate.LocalStoreAdapter());

    UI.addEventListener('annotation:click', (event) => {
      let comments = [...this.state.comments];

      comments = comments.map((comment) => {
        let copy = { ...comment };

        copy.selected = false;
        if (comment.uuid === event.getAttribute('data-pdf-annotate-id')) {
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


    window.addEventListener('keyup', (event) => {
      if (event.key === 'n') {
        // Enabling point allows you to add comments.
        UI.enablePoint();
        UI.disableEdit();
      }
      if (event.key === 'm') {
        // Enabling edit allows you to select comments.
        UI.disablePoint();
        UI.enableEdit();
      }
    });
  }

  componentWillUnmount = () => {
    this.removeEventListeners();
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

      return <div
          onClick={this.scrollToAnnotation(comment.uuid)}
          className={`cf-pdf-comment-list-item${selectedClass}`}
          key={`comment${index}`}>
          {comment.content}
        </div>;
    });

    return (
      <div>
        <div className="cf-pdf-page-container">
          <div className="cf-pdf-container">
            <div className="cf-pdf-header">
              <div className="usa-grid-full">
                <div className="usa-width-one-third cf-pdf-buttons-left">
                  {this.props.file}
                </div>
                <div className="usa-width-one-third cf-pdf-buttons-center">
                  {this.state.currentPage} / {this.state.numPages}
                </div>
                <div className="usa-width-one-third cf-pdf-buttons-right">
                  
                  <Button name="previous" classNames={["cf-pdf-button"]} onClick={this.props.previousPdf}>
                    <i className="fa fa-chevron-left" aria-hidden="true"></i>Previous
                  </Button>
                  <Button name="next" classNames={["cf-pdf-button"]} onClick={this.props.nextPdf}>
                    Next<i className="fa fa-chevron-right" aria-hidden="true"></i>
                  </Button>
                </div>
              </div>
            </div>
            <div id="scrollWindow" className="cf-pdf-scroll-view">
              <div id="viewer" className="cf-crosshair-cursor cf-pdf-page pdfViewer singlePageView"></div>
            </div>
            <div className="cf-pdf-footer">
              <div className="usa-grid-full">
                <div className="usa-width-one-third cf-pdf-buttons-left">
                  <Button name="previous" classNames={["cf-pdf-bookmarks cf-pdf-button"]} onClick={this.zoom(-.3)}>
                    <i style={{color:'cyan'}} className="fa fa-bookmark" aria-hidden="true"></i>
                  </Button>
                  <Button name="previous" classNames={["cf-pdf-bookmarks cf-pdf-button"]} onClick={this.zoom(-.3)}>
                    <i style={{color:'orange'}} className="fa fa-bookmark" aria-hidden="true"></i>
                  </Button>
                  <Button name="previous" classNames={["cf-pdf-bookmarks cf-pdf-button"]} onClick={this.zoom(-.3)}>
                    <i style={{color:'white'}} className="fa fa-bookmark" aria-hidden="true"></i>
                  </Button>
                  <Button name="previous" classNames={["cf-pdf-bookmarks cf-pdf-button"]} onClick={this.zoom(-.3)}>
                    <i style={{color:'magenta'}} className="fa fa-bookmark" aria-hidden="true"></i>
                  </Button>
                  <Button name="previous" classNames={["cf-pdf-bookmarks cf-pdf-button"]} onClick={this.zoom(-.3)}>
                    <i style={{color:'green'}} className="fa fa-bookmark" aria-hidden="true"></i>
                  </Button>
                  <Button name="previous" classNames={["cf-pdf-bookmarks cf-pdf-button"]} onClick={this.zoom(-.3)}>
                    <i style={{color:'yellow'}} className="fa fa-bookmark" aria-hidden="true"></i>
                  </Button>
                </div>
                <div className="usa-width-one-third cf-pdf-buttons-center">
                  <Button name="previous" classNames={["cf-pdf-button"]} onClick={this.zoom(-.3)}>
                    <i className="fa fa-minus" aria-hidden="true"></i>
                  </Button>
                  <Button name="fit" classNames={["cf-pdf-button"]} onClick={this.zoom(1)}>
                    <i className="cf-pdf-button fa fa-arrows-alt" aria-hidden="true"></i>
                  </Button>
                  <Button name="previous" classNames={["cf-pdf-button"]} onClick={this.zoom(.3)}>
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
          <div className="cf-comment-wrapper">
            <div className="cf-heading-alt">Document</div>
            <p className="cf-pdf-meta-title"><b>Filename:</b></p>
            <p className="cf-pdf-meta-title"><b>Document Type:</b></p>
            <p className="cf-pdf-meta-title"><b>Receipt Date:</b> 01/02/2017</p>
            <div className="cf-heading-alt">
              Notes
              <span className="cf-right-side">
                <a onClick={this.addNote}>+ Add a Note</a>
              </span>
              <i className="fa fa-pencil" aria-hidden="true"></i>
            </div>
            <div className="cf-pdf-comment-list">
              <div className="cf-pdf-comment-list-item" hidden={!this.state.isAddingComment}>
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
    );
  }
}

PdfViewer.propTypes = {
  file: PropTypes.string.isRequired
};
