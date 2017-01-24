import React, { PropTypes } from 'react';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import PDFJSAnnotate from 'pdf-annotate.js';
import DateSelector from '../components/DateSelector';
import DropDown from '../components/DropDown';
import Button from '../components/Button';

export default class PdfViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      comments: [],
      currentPage: 1,
      numPages: 0
    };
  }

  generateComments = (pdfDocument) => {
    this.comments = [];
    let storeAdapter = PDFJSAnnotate.getStoreAdapter();

    this.setState({ comments: this.comments });
    for (let i = 0; i < pdfDocument.pdfInfo.numPages; i++) {
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

  renderPage = (index) => {
    const { UI } = PDFJSAnnotate;

    let RENDER_OPTIONS = {
      documentId: this.props.file,
      pdfDocument: this.state.pdfDocument,
      rotate: 0,
      scale: 1
    };

    this.isRendered[index] = true;
    UI.renderPage(index + 1, RENDER_OPTIONS).catch(() => {
      this.isRendered[index] = false;
    });
  }

  draw = () => {
    const { UI } = PDFJSAnnotate;

    PDFJS.getDocument(this.props.file).then((pdfDocument) => {
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
    });
  }

  componentWillReceiveProps(oldProps) {
    if (oldProps.file !== this.props.file) {
      document.getElementById('scrollWindow').scrollTop = 0;
      this.draw();
    }
  }

  componentDidMount = () => {
    const { UI } = PDFJSAnnotate;

    PDFJS.workerSrc = '../assets/dist/pdf.worker.js';
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

    this.draw();


    // Scroll event to render pages as they come into view
    let scrollWindow = document.getElementById('scrollWindow');

    scrollWindow.addEventListener('scroll', () => {
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
    });


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
                  <i className="cf-pdf-button fa fa-download" aria-hidden="true"></i>
                  <i className="cf-pdf-button fa fa-print" aria-hidden="true"></i>
                </div>
              </div>
            </div>
            <div id="scrollWindow" className="cf-pdf-scroll-view">
              <div id="viewer" className="cf-crosshair-cursor cf-pdf-page pdfViewer singlePageView"></div>
            </div>
            <div className="cf-pdf-footer">
              <div className="usa-grid-full">
                <div className="usa-width-one-third cf-pdf-buttons-left">
                  <Button name="previous" classNames={["cf-pdf-button"]} onClick={this.props.previousPdf}>
                    <i className="fa fa-chevron-left" aria-hidden="true"></i> Previous
                  </Button>
                </div>
                <div className="usa-width-one-third cf-pdf-buttons-center">
                  <i className="cf-pdf-button fa fa-minus" aria-hidden="true"></i>
                  <i className="cf-pdf-button fa fa-arrows-alt" aria-hidden="true"></i>
                  <i className="cf-pdf-button fa fa-plus" aria-hidden="true"></i>
                </div>
                <div className="usa-width-one-third cf-pdf-buttons-right">
                  <Button name="next" classNames={["cf-pdf-button"]} onClick={this.props.nextPdf}>
                    Next <i className="cf-pdf-button fa fa-chevron-right" aria-hidden="true"></i>
                  </Button>
                </div>
              </div>
            </div>
          </div>
          <div className="cf-comment-wrapper">
            <div className="cf-heading-alt">Document</div>
            <p className="cf-pdf-meta-title"><b>Filename:</b></p>
            <p className="cf-pdf-meta-title"><b>Document Type:</b></p>
            <DateSelector
             label="Receipt Date:"
             name="date"
             value="01/02/2017"
            />
            <DropDown
             label="Document Tab"
             name="documentTab"
             options={["one", "two"]}
             value="one"
            />
            <div className="cf-heading-alt">
              Notes
              <span className="cf-right-side">
                <a href="#">+ Add a Note</a>
              </span>
              <i className="fa fa-pencil" aria-hidden="true"></i>
            </div>
            <div className="cf-pdf-comment-list">
              <div className="cf-pdf-comment">
                {comments}
              </div>
              <form className="comment-list-form" style={{ display: 'none' }}>
                <input type="text" placeholder="Add a Comment"/>
              </form>
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
