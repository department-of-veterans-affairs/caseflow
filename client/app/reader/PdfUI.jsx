import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import DocumentSearch from './DocumentSearch';
import Button from '../components/Button';
import Link from '../components/Link';
import PdfUIPageNumInput from '../reader/PdfUIPageNumInput';
import Pdf from './Pdf';
import DocumentCategoryIcons from './DocumentCategoryIcons';
import { connect } from 'react-redux';
import { resetJumpToPage, togglePdfSidebar, toggleSearchBar
} from '../reader/PdfViewer/PdfViewerActions';
import { selectCurrentPdf, rotateDocument } from '../reader/Documents/DocumentsActions';
import { stopPlacingAnnotation } from '../reader/AnnotationLayer/AnnotationActions';
import { docListIsFiltered } from '../reader/selectors';
import { DownloadIcon, FilterIcon, PageArrowLeft, PageArrowRight, LeftChevron,
  ExternalLink, FitToScreen, Rotate, SearchIcon } from '../components/RenderFunctions';
import classNames from 'classnames';
import _ from 'lodash';
import { CATEGORIES, ACTION_NAMES, INTERACTION_TYPES } from '../reader/analytics';

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
      currentPage: 1
    };
  }

  componentDidUpdate(prevProps) {
    // when a document changes, remove annotation state
    if (prevProps.doc.id !== this.props.doc.id) {
      if (this.props.isPlacingAnnotation) {
        this.props.stopPlacingAnnotation('from-document-change');
      }
      this.props.resetJumpToPage();
    }
  }

  zoom = (delta) => () => {
    const nextScale = Math.max(MINIMUM_ZOOM, _.round(this.state.scale + delta, 2));
    const zoomDirection = delta > 0 ? 'in' : 'out';

    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, `zoom ${zoomDirection}`, nextScale);

    this.setState({
      scale: nextScale
    });
  }

  openDownloadLink = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'download');
    window.open(`${this.props.doc.content_url}?type=${this.props.doc.type}&download=true`);
  }

  showPreviousDocument = () => {
    window.analyticsEvent(
      CATEGORIES.VIEW_DOCUMENT_PAGE,
      ACTION_NAMES.VIEW_PREVIOUS_DOCUMENT,
      INTERACTION_TYPES.VISIBLE_UI
    );
    this.props.showPdf(this.props.prevDocId)();
    this.props.stopPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI);
  }

  showNextDocument = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, ACTION_NAMES.VIEW_NEXT_DOCUMENT, INTERACTION_TYPES.VISIBLE_UI);
    this.props.showPdf(this.props.nextDocId)();
    this.props.stopPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI);
  }

  getPageIndicator = () => {
    let content = <em>Loading document...</em>;

    if (this.props.numPages) {
      content = <span>
        <PdfUIPageNumInput
          currentPage={this.state.currentPage}
          numPages={this.props.numPages}
          docId={this.props.doc.id}
          onPageChange={this.onPageChange}
        />
        of {this.props.numPages}
      </span>;
    }

    return <span><span className="page-progress-indicator">{content}</span>|</span>;
  }

  getPdfFooter = () => {
    const currentDocIndex = this.props.filteredDocIds.indexOf(this.props.doc.id);

    return <div className="cf-pdf-footer cf-pdf-toolbar">
      <div className="cf-pdf-footer-buttons-left">
        { this.props.prevDocId &&
            <Button
              name="previous"
              classNames={['cf-pdf-button']}
              onClick={this.showPreviousDocument}
              ariaLabel="previous PDF">
              <PageArrowLeft /><span className="left-button-label">Previous</span>
            </Button>
        }
      </div>
      <div className="cf-pdf-buttons-center">
        { !this.props.loadError && this.getPageIndicator() }
        <span className="doc-list-progress-indicator">{this.props.docListIsFiltered && <FilterIcon />}
          Document {currentDocIndex + 1} of {this.props.filteredDocIds.length}
        </span>
      </div>
      <div className="cf-pdf-footer-buttons-right">
        { this.props.nextDocId &&
              <Button
                name="next"
                classNames={['cf-pdf-button cf-right-side']}
                onClick={this.showNextDocument}
                ariaLabel="next PDF">
                <span className="right-button-label">Next</span><PageArrowRight />
              </Button>
        }
      </div>
    </div>;
  }

  rotateDocument = () => {
    this.props.rotateDocument(this.props.doc.id);
  }

  fitToScreen = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'fit to screen');

    this.setState({
      scale: this.state.fitToScreenZoom
    });
  }

  onPageChange = (currentPage, fitToScreenZoom) => {
    this.setState({
      currentPage,
      fitToScreenZoom
    });
  }

  onBackToClaimsFolder = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'back-to-claims-folder');
    this.props.stopPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI);
  }

  handleClickDocumentTypeLink = () => window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'document-type-link')

  render() {
    const pdfUiClass = classNames(
      'cf-pdf-container',
      { 'hidden-sidebar': this.props.hidePdfSidebar });

    return <div className={pdfUiClass}>
      <div className="cf-pdf-header cf-pdf-toolbar usa-grid-full">
        <span className="usa-width-one-third cf-pdf-buttons-left">
          { this.props.showClaimsFolderNavigation && <Link
            to={`${this.props.documentPathBase}`}
            name="backToClaimsFolder"
            button="matte"
            onClick={this.onBackToClaimsFolder}>
            <LeftChevron />
            &nbsp; Back to claims folder
          </Link> }
        </span>
        <span className="usa-width-one-third cf-pdf-buttons-center">
          <span className="category-icons-and-doc-type">
            <span className="cf-pdf-doc-category-icons">
              <DocumentCategoryIcons doc={this.props.doc} />
            </span>
            <span className="cf-pdf-doc-type-button-container">
              <Link
                name="newTab"
                ariaLabel="open document in new tab"
                target="_blank"
                button="matte"
                onClick={this.handleClickDocumentTypeLink}
                href={`/reader/appeal${this.props.documentPathBase}/${this.props.doc.id}`}>
                <h1 className="cf-pdf-vertically-center cf-non-stylized-header">
                  <span title="Open in new tab">{this.props.doc.type}</span>
                  <span className="cf-pdf-external-link-icon"><ExternalLink /></span>
                </h1>
              </Link>
            </span>
          </span>
        </span>
        <span className="usa-width-one-third cf-pdf-buttons-right">
          Zoom:
          <Button
            name="zoomOut"
            classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
            onClick={this.zoom(-ZOOM_RATE)}
            ariaLabel="zoom out">
            <i className="fa fa-minus" aria-hidden="true" />
          </Button>
          <Button
            name="zoomIn"
            classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
            onClick={this.zoom(ZOOM_RATE)}
            ariaLabel="zoom in">
            <i className="fa fa-plus" aria-hidden="true" />
          </Button>
          <Button
            name="fit"
            classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
            onClick={this.fitToScreen}
            ariaLabel="fit to screen">
            <FitToScreen />
          </Button>
          <Button
            name="rotation"
            classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
            onClick={this.rotateDocument}
            ariaLabel="rotate document">
            <Rotate />
          </Button>
          <span className="cf-pdf-spaced-buttons">|</span>
          <Button
            name="download"
            classNames={['cf-pdf-button cf-pdf-download-icon']}
            onClick={this.openDownloadLink}
            ariaLabel="download pdf">
            <DownloadIcon />
          </Button>
          <Button
            name="search"
            classNames={['cf-pdf-button cf-pdf-search usa-search usa-search-small']}
            ariaLabel="search text"
            type="submit"
            onClick={this.props.toggleSearchBar}>
            <SearchIcon />
          </Button>
          {this.props.hidePdfSidebar &&
            <span className="cf-pdf-open-menu">
              <Button
                name="open menu"
                classNames={['cf-pdf-button']}
                onClick={this.props.togglePdfSidebar}>
                <strong>
                  Open menu
                </strong>
              </Button>
            </span>}
        </span>
      </div>
      <div>
        <DocumentSearch file={this.props.doc.content_url} />
        <Pdf
          documentId={this.props.doc.id}
          documentPathBase={this.props.documentPathBase}
          documentType={this.props.doc.type}
          file={this.props.doc.content_url}
          pdfWorker={this.props.pdfWorker}
          id={this.props.id}
          history={this.props.history}
          onPageClick={this.props.onPageClick}
          scale={this.state.scale}
          onPageChange={this.onPageChange}
          prefetchFiles={this.props.prefetchFiles}
          resetJumpToPage={this.props.resetJumpToPage}
        />
      </div>
      { this.getPdfFooter() }
    </div>;
  }
}

const mapStateToProps = (state, props) => {
  const pdfDocument = _.get(state.pdf.pdfDocuments, [props.doc.content_url]);
  const numPages = pdfDocument ? pdfDocument.pdfInfo.numPages : null;

  return {
    ..._.pick(state.documentList, 'filteredDocIds'),
    docListIsFiltered: docListIsFiltered(state),
    loadError: state.pdf.documentErrors[props.doc.content_url],
    isPlacingAnnotation: state.annotationLayer.isPlacingAnnotation,
    ..._.pick(state.pdfViewer, 'hidePdfSidebar'),
    numPages
  };
};
const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    stopPlacingAnnotation,
    togglePdfSidebar,
    resetJumpToPage,
    rotateDocument,
    selectCurrentPdf,
    toggleSearchBar
  }, dispatch)
);

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfUI);

PdfUI.propTypes = {
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    filename: PropTypes.string,
    id: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.number]),
    type: PropTypes.string,
    receivedAt: PropTypes.string
  }).isRequired,
  id: PropTypes.string.isRequired,
  pdfWorker: PropTypes.string.isRequired,
  onPageClick: PropTypes.func,
  onShowList: PropTypes.func,
  togglePdfSidebar: PropTypes.func,
  nextDocId: PropTypes.number,
  prevDocId: PropTypes.number,
  selectCurrentPdf: PropTypes.func,
  showClaimsFolderNavigation: PropTypes.bool.isRequired,
  prefetchFiles: PropTypes.arrayOf(PropTypes.string),
  hidePdfSidebar: PropTypes.bool,
  featureToggles: PropTypes.object,
  showPdf: PropTypes.func
};
