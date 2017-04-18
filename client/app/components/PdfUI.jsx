import React, { PropTypes } from 'react';
import Button from '../components/Button';
import Pdf from '../components/Pdf';
import DocumentCategoryIcons from '../components/DocumentCategoryIcons';

export const linkToSingleDocumentView = (doc) => {
  let id = doc.id;
  let filename = doc.filename;
  let type = doc.type;
  let receivedAt = doc.receivedAt;

  return `${window.location.href}/${id}?type=${type}` +
    `&received_at=${receivedAt}&filename=${filename}`;
};

const ZOOM_RATE = 0.3;
const MINIMUM_ZOOM = 0.1;

// The PdfUI component displays the PDF with surrounding UI
// controls. We currently support the following controls:
//
// Zoom In & Out: A plus and minus to zoom in and out.
// Page number: Shows what page you're currently on, out of the
//   total number of pages.
// Document name: The document name is in the top right corner.
//   it is currently a link to open the document in a new tab.
// Next & Previous PDF: If you have several PDFs you would like
//   a user to be able to navigate to, pass in handlers for onNextPdf
//   and onPreviousPdf. If one is not supplied, or is null, then the
//   corresponding arrow will be missing.
export default class PdfUI extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      scale: 1,
      currentPage: 1,
      numPages: 1
    };
  }

  zoom = (delta) => () => {
    // TODO: Fix scrolling when zooming
    // let zoomFactor = (this.state.scale + delta) / this.state.scale;

    this.setState({
      scale: Math.max(MINIMUM_ZOOM, this.state.scale + delta)
    });
    // this.draw(this.props.file,
    //   document.getElementById('scrollWindow').scrollTop * zoomFactor);
  }

  fitToScreen = () => {
    this.setState({
      scale: 1
    });
  }

  onPageChange = (currentPage, numPages) => {
    this.setState({
      currentPage,
      numPages
    });
  }

  render() {
    let selectedLabels = {};

    selectedLabels[this.props.label] = true;

    return <div className="cf-pdf-container">
      <div className="cf-pdf-header cf-pdf-toolbar">
        <div className="usa-grid-full">
          <span className="usa-width-one-third cf-pdf-buttons-left">
            { this.props.onShowList &&
              <Button
                name="backToDocuments"
                classNames={["cf-pdf-button"]}
                onClick={this.props.onShowList}>
                <i className="fa fa-chevron-left" aria-hidden="true"></i>
                &nbsp; View all documents
              </Button> }
          </span>
          <span className="usa-width-one-third cf-pdf-buttons-center">
            <Button
              name="zoomOut"
              classNames={["cf-pdf-button cf-pdf-spaced-buttons"]}
              onClick={this.zoom(-ZOOM_RATE)}
              ariaLabel="zoom out">
              <i className="fa fa-minus" aria-hidden="true"></i>
            </Button>
            <Button
              name="fit"
              classNames={["cf-pdf-button cf-pdf-spaced-buttons"]}
              onClick={this.fitToScreen}
              ariaLabel="fit to screen">
              <i className="fa fa-arrows-alt" aria-hidden="true"></i>
            </Button>
            <Button
              name="zoomIn"
              classNames={["cf-pdf-button cf-pdf-spaced-buttons"]}
              onClick={this.zoom(ZOOM_RATE)}
              ariaLabel="zoom in">
              <i className="fa fa-plus" aria-hidden="true"></i>
            </Button>
          </span>
          <span className="usa-width-one-third">
            <span className="cf-right-side">
              <DocumentCategoryIcons docId={this.props.doc.id} />
              <Button
                name="newTab"
                classNames={["cf-pdf-button"]}
                ariaLabel="open document in new tab"
                onClick={() => window.open(
                  linkToSingleDocumentView(this.props.doc), '_blank')}>
                {this.props.doc.type}
              </Button>
            </span>
          </span>
        </div>
      </div>
      <div className="cf-pdf-navigation">
        { this.props.onPreviousPdf &&
          <span className="cf-pdf-buttons-left">
            <Button
              name="previous"
              classNames={["cf-pdf-button"]}
              onClick={this.props.onPreviousPdf}
              ariaLabel="previous PDF">
              <i className="fa fa-arrow-circle-left fa-3x" aria-hidden="true"></i>
            </Button>
          </span> }
        { this.props.onNextPdf &&
          <span className="cf-pdf-buttons-right">
            <Button
              name="next"
              classNames={["cf-pdf-button cf-right-side"]}
              onClick={this.props.onNextPdf}
              ariaLabel="next PDF">
              <i className="fa fa-arrow-circle-right fa-3x" aria-hidden="true"></i>
            </Button>
          </span> }
      </div>
      <div>
        <Pdf
          comments={this.props.comments}
          documentId={this.props.doc.id}
          file={this.props.file}
          pdfWorker={this.props.pdfWorker}
          id={this.props.id}
          onPageClick={this.props.onPageClick}
          scale={this.state.scale}
          onPageChange={this.onPageChange}
          onCommentClick={this.props.onCommentClick}
          onCommentScrolledTo={this.props.onCommentScrolledTo}
          onIconMoved={this.props.onIconMoved}
        />
      </div>
      <div className="cf-pdf-footer cf-pdf-toolbar">
        <div>
          <div className="cf-pdf-buttons-center">
            Page {this.state.currentPage} of {this.state.numPages}
          </div>
        </div>
      </div>
    </div>;
  }
}

PdfUI.propTypes = {
  comments: PropTypes.arrayOf(PropTypes.shape({
    content: PropTypes.string,
    uuid: PropTypes.number
  })),
  doc: PropTypes.shape({
    filename: PropTypes.string,
    id: React.PropTypes.oneOfType([
      React.PropTypes.string,
      React.PropTypes.number]),
    type: PropTypes.string,
    receivedAt: PropTypes.string
  }).isRequired,
  file: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  pdfWorker: PropTypes.string.isRequired,
  onPageClick: PropTypes.func,
  onShowList: PropTypes.func,
  onNextPdf: PropTypes.func,
  onPreviousPdf: PropTypes.func,
  onCommentClick: PropTypes.func,
  onCommentScrolledTo: PropTypes.func,
  onIconMoved: PropTypes.func
};
