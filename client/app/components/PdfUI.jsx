import React from 'react';
import PropTypes from 'prop-types';

import Button from '../components/Button';
import Pdf from '../components/Pdf';
import DocumentCategoryIcons from '../components/DocumentCategoryIcons';
import { connect } from 'react-redux';
import * as Constants from '../reader/constants';
import { selectCurrentPdf, stopPlacingAnnotation } from '../reader/actions';
import { docListIsFiltered } from '../reader/selectors';
import { FilterIcon } from '../components/RenderFunctions';
import classNames from 'classnames';
import _ from 'lodash';

export const linkToSingleDocumentView = (basePath, doc) => {
  let id = doc.id;
  let filename = doc.filename;
  let type = doc.type;
  let receivedAt = doc.receivedAt;

  return `${basePath}/${id}?type=${type}` +
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
export class PdfUI extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      scale: 1,
      currentPage: 1,
      numPages: null
    };
  }
  componentDidUpdate(prevProps) {
    // when a document changes, remove annotation state
    if (prevProps.doc.id !== this.props.doc.id && this.props.isPlacingAnnotation) {
      this.props.stopPlacingAnnotation();
    }
  }
  zoom = (delta) => () => {
    this.setState({
      scale: Math.max(MINIMUM_ZOOM, this.state.scale + delta)
    });
  }

  getPdfFooter = () => {
    if (_.get(this.props.pdfsReadyToShow, this.props.doc.id) && this.state.numPages) {
      const currentDocIndex = this.props.filteredDocIds.indexOf(this.props.doc.id);

      return <div className="cf-pdf-buttons-center">
        <span className="page-progress-indicator">Page {this.state.currentPage} of {this.state.numPages}{' '}</span>
        | 
        <span className="doc-list-progress-indicator">{this.props.docListIsFiltered && <FilterIcon />}
          Document {currentDocIndex + 1} of {this.props.filteredDocIds.length}
        </span>
      </div>;
    }

    return '';
  }

  fitToScreen = () => {
    this.setState({
      scale: this.state.fitToScreenZoom
    });
  }

  onPageChange = (currentPage, numPages, fitToScreenZoom) => {
    this.setState({
      currentPage,
      numPages,
      fitToScreenZoom
    });
  }

  render() {
    const pdfUiClass = classNames(
      'cf-pdf-container',
      { 'hidden-sidebar': this.props.hidePdfSidebar });

    return <div className={pdfUiClass}>
      <div className="cf-pdf-header cf-pdf-toolbar usa-grid-full">
        <span className="usa-width-one-third cf-pdf-buttons-left">
          { this.props.showDocumentsListNavigation && <Button
            name="backToDocuments"
            classNames={['cf-pdf-button cf-pdf-cutoff cf-pdf-buttons-left']}
            onClick={this.props.onShowList}>
            <i className="fa fa-chevron-left" aria-hidden="true"></i>
            &nbsp; Back to all documents
          </Button> }
        </span>
        <span className="usa-width-one-third cf-pdf-buttons-center">
          <Button
            name="zoomOut"
            classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
            onClick={this.zoom(-ZOOM_RATE)}
            ariaLabel="zoom out">
            <i className="fa fa-minus" aria-hidden="true"></i>
          </Button>
          <Button
            name="fit"
            classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
            onClick={this.fitToScreen}
            ariaLabel="fit to screen">
            <i className="fa fa-arrows-alt" aria-hidden="true"></i>
          </Button>
          <Button
            name="zoomIn"
            classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
            onClick={this.zoom(ZOOM_RATE)}
            ariaLabel="zoom in">
            <i className="fa fa-plus" aria-hidden="true"></i>
          </Button>
        </span>
        <span className="usa-width-one-third">
          <span className="category-icons-and-doc-type">
            <span className="cf-pdf-doc-category-icons">
              <DocumentCategoryIcons doc={this.props.doc} />
            </span>
            <span className="cf-pdf-doc-type-button-container">
              <Button
                name="newTab"
                classNames={['cf-pdf-button cf-pdf-doc-type-button']}
                ariaLabel="open document in new tab"
                onClick={() => window.open(
                  linkToSingleDocumentView(this.props.documentPathBase, this.props.doc), '_blank')}>
                <span title={this.props.doc.type}>{this.props.doc.type}</span>
              </Button>
            </span>
            {this.props.hidePdfSidebar &&
              <span className="cf-pdf-open-menu">
                <Button
                  name="open menu"
                  classNames={['cf-pdf-button']}
                  onClick={this.props.handleTogglePdfSidebar}>
                  <strong>
                    Open menu
                  </strong>
                </Button>
              </span>}
            </span>
        </span>
      </div>
      <div className="cf-pdf-navigation">
        { this.props.prevDocId &&
          <span className="cf-pdf-buttons-left">
            <Button
              name="previous"
              classNames={['cf-pdf-button']}
              onClick={this.props.showPdf(this.props.prevDocId)}
              ariaLabel="previous PDF">
              <i className="fa fa-arrow-circle-left fa-3x" aria-hidden="true"></i>
            </Button>
          </span> }
        { this.props.nextDocId &&
          <span className="cf-pdf-buttons-right">
            <Button
              name="next"
              classNames={['cf-pdf-button cf-right-side']}
              onClick={this.props.showPdf(this.props.nextDocId)}
              ariaLabel="next PDF">
              <i className="fa fa-arrow-circle-right fa-3x" aria-hidden="true"></i>
            </Button>
          </span> }
      </div>
      <div>
        <Pdf
          documentId={this.props.doc.id}
          file={this.props.file}
          pdfWorker={this.props.pdfWorker}
          id={this.props.id}
          onPageClick={this.props.onPageClick}
          scale={this.state.scale}
          onPageChange={this.onPageChange}
          onCommentScrolledTo={this.props.onCommentScrolledTo}
        />
      </div>
      <div className="cf-pdf-footer cf-pdf-toolbar">
        { this.getPdfFooter(this.props, this.state) }
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  ..._.pick(state.ui, 'filteredDocIds'),
  docListIsFiltered: docListIsFiltered(state),
  ...state.ui.pdf
});
const mapDispatchToProps = (dispatch) => ({
  stopPlacingAnnotation: () => {
    dispatch(stopPlacingAnnotation());
  },
  selectCurrentPdf: (docId) => dispatch(selectCurrentPdf(docId)),
  handleTogglePdfSidebar() {
    dispatch({
      type: Constants.TOGGLE_PDF_SIDEBAR
    });
  }
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfUI);

PdfUI.propTypes = {
  doc: PropTypes.shape({
    filename: PropTypes.string,
    id: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.number]),
    type: PropTypes.string,
    receivedAt: PropTypes.string
  }).isRequired,
  file: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  pdfWorker: PropTypes.string.isRequired,
  onPageClick: PropTypes.func,
  onShowList: PropTypes.func,
  onCommentScrolledTo: PropTypes.func,
  handleTogglePdfSidebar: PropTypes.func,
  nextDocId: PropTypes.number,
  prevDocId: PropTypes.number,
  selectCurrentPdf: PropTypes.func,
  showDocumentsListNavigation: PropTypes.bool.isRequired,
  hidePdfSidebar: PropTypes.bool
};
