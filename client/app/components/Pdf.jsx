import React, { PropTypes } from 'react';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import PDFJSAnnotate from 'pdf-annotate.js';

export default class Pdf extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      numPages: 0
    };
  }

  renderPage = (index) => {
    const { UI } = PDFJSAnnotate;
    console.log('rendering'+index);
    let RENDER_OPTIONS = {
      documentId: this.props.documentId,
      pdfDocument: this.state.pdfDocument,
      rotate: 0,
      scale: this.props.scale
    };

    this.isRendered[index] = true;

    // Call into PDFJSAnnotate to render this page
    UI.renderPage(index + 1, RENDER_OPTIONS).then(([pdfPage]) => {
      // If successful then we want to setup a click handler
      let pageContainer = document.getElementById(`pageContainer${index + 1}`);

      pageContainer.addEventListener('click',
        this.onPageClick(pdfPage.getViewport(this.props.scale, 0), index + 1));
    }).
    catch(() => {
      // If unsuccessful we want to mark this page as not rendered
      this.isRendered[index] = false;
    });
  }

  onPageClick = (viewport, pageNumber) => (event) => {
    if (this.props.onPageClick) {
      let annotation = {
        class: "Annotation",
        page: pageNumber,
        "type": "point",
        "x": (event.offsetX + event.target.offsetLeft) / this.props.scale,
        "y": (event.offsetY + event.target.offsetTop) / this.props.scale
      };

      this.props.onPageClick(viewport, pageNumber, annotation);
    }
  }

  createPages = (pdfDocument) => {
    const { UI } = PDFJSAnnotate;

    // Create a page in the DOM for every page in the PDF
    let viewer = document.getElementById(this.props.id);

    // If the user has switched to the list view and this element doesnt
    // exist then don't try to render the PDF.
    // TODO: look into just hiding the PDFs instead of removing them.
    if (!viewer) {
      return;
    }

    viewer.innerHTML = '';
    
    for (let i = 0; i < pdfDocument.pdfInfo.numPages; i++) {
      let page = UI.createPage(i + 1);
      viewer.appendChild(page);
    }
  }

  scrollEvent = () => {
    let page = document.getElementsByClassName('page');
    let scrollWindow = document.getElementById('scrollWindow');

    Array.prototype.forEach.call(page, (ele, index) => {
      let boundingRect = ele.getBoundingClientRect();

      // You are on this page, if the top of the page is above the middle
      // and the bottom of the page is below the middle
      if (this.props.onPageChange &&
          boundingRect.top < scrollWindow.clientHeight / 2 &&
          boundingRect.bottom > scrollWindow.clientHeight / 2) {
        this.props.onPageChange(index + 1, this.state.numPages);
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

  draw = (file, scrollLocation = 0) => {
    PDFJS.getDocument(file).then((pdfDocument) => {
      this.isRendered = new Array(pdfDocument.pdfInfo.numPages);
      this.setState({
        numPages: pdfDocument.pdfInfo.numPages,
        pdfDocument
      }, () => {
        this.createPages(pdfDocument);
        // Automatically render the first page
        // This assumes that page has already been created and appended
        this.renderPage(0);
      });

      if (this.props.onPageChange) {
        this.props.onPageChange(1, pdfDocument.pdfInfo.numPages);
      }

      document.getElementById('scrollWindow').scrollTop = scrollLocation;
      this.scrollEvent();
    });
  }

  componentDidMount = () => {
    PDFJS.workerSrc = this.props.pdfWorker;

    this.draw(this.props.file);

    // Scroll event to render pages as they come into view
    let scrollWindow = document.getElementById('scrollWindow');

    scrollWindow.addEventListener('scroll', this.scrollEvent);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.file !== this.props.file) {
      document.getElementById('scrollWindow').scrollTop = 0;
      this.draw(nextProps.file);
    }

    if (nextProps.scale !== this.props.scale) {
      this.draw(nextProps.file);
    }
  }

  render() {
    return <div id="scrollWindow" className="cf-pdf-scroll-view">
        <div
          id={this.props.id}
          className={`cf-pdf-page pdfViewer singlePageView`}>
        </div>
      </div>;
  }
}

Pdf.defaultProps = {
  scale: 1
};

Pdf.propTypes = {
  documentId: PropTypes.number.isRequired,
  file: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  pdfWorker: PropTypes.string.isRequired,
  scale: PropTypes.number,
  onPageClick: PropTypes.func,
  onPageChange: PropTypes.func
};
