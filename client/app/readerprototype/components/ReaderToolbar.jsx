import PropTypes from 'prop-types';
import React, { useState } from 'react';
import { useDispatch } from 'react-redux';

import Button from '../../components/Button';
import { DownloadIcon } from '../../components/icons/DownloadIcon';
import { ExternalLinkIcon } from '../../components/icons/ExternalLinkIcon';
import { FitToScreenIcon } from '../../components/icons/FitToScreenIcon';
import { LeftChevronIcon } from '../../components/icons/LeftChevronIcon';
import { RotateIcon } from '../../components/icons/RotateIcon';
import { SearchIcon } from '../../components/icons/SearchIcon';
import Link from '../../components/Link';
import { INTERACTION_TYPES } from '../../reader/analytics';
import { stopPlacingAnnotation } from '../../reader/AnnotationLayer/AnnotationActions';
import DocumentCategoryIcons from '../../reader/DocumentCategoryIcons';
import { togglePdfSidebar } from '../../reader/PdfViewer/PdfViewerActions';
import { CATEGORIES } from '../utils/readerConstants';
import { pdfToolbarStyles } from '../utils/styles';

const ReaderToolbar = ({
  resetZoomLevel,
  documentPathBase,
  doc,
  showClaimsLink,
  setZoomOutLevel,
  disableZoomOut,
  setZoomInLevel,
  disableZoomIn,
  zoomLevel,
  rotateDocument,
  toggleSearchBar,
  showSearchBar,
  hideSideBar,
}) => {
  // eslint-disable-next-line no-unused-vars
  const [_searchTerm, setSearchTerm] = useState(null);

  const onToggleSearchBar = () => {
    if (showSearchBar) {
      setSearchTerm(null);
      toggleSearchBar(false);

      return;
    }
    toggleSearchBar(true);
  };

  const dispatch = useDispatch();

  const handleClickDocumentTypeLink = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'document-type-link');
  };

  const openDownloadLink = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'download');
    window.open(`${doc.content_url}?type=${doc.type}&download=true`);
  };

  const onBackToClaimsFolder = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'back-to-claims-folder');
    dispatch(stopPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI));
  };

  return (
    <div id="prototype-toolbar" className="cf-pdf-header cf-pdf-toolbar">
      <div className="toolbar-section" {...pdfToolbarStyles.toolbar} {...pdfToolbarStyles.toolbarLeft}>
        {showClaimsLink && (
          <Link
            to={`${documentPathBase}`}
            name="backToClaimsFolder"
            button="matte"
            onClick={onBackToClaimsFolder}>
            <LeftChevronIcon />
            &nbsp; Back
          </Link>
        )}
      </div>
      <div className="toolbar-section" {...pdfToolbarStyles.toolbar} {...pdfToolbarStyles.toolbarCenter}>
        <span className="category-icons-and-doc-type">
          <span className="cf-pdf-doc-category-icons">
            <DocumentCategoryIcons doc={doc} />
          </span>
          <span className="cf-pdf-doc-type-button-container">
            <Link
              name="newTab"
              ariaLabel="open document in new tab"
              target="_blank"
              button="matte"
              onClick={() => handleClickDocumentTypeLink()}
              href={`/reader/appeal${documentPathBase}/${doc.id}`}
            >
              <h1 className="cf-pdf-vertically-center cf-non-stylized-header">
                <span title="Open in new tab">{doc.type}</span>
                <span className="cf-pdf-external-link-icon">
                  <ExternalLinkIcon />
                </span>
              </h1>
            </Link>
          </span>
        </span>
      </div>
      <div className="toolbar-section"  {...pdfToolbarStyles.toolbar} {...pdfToolbarStyles.toolbarRight}>
        <span className="cf-pdf-button-text">Zoom:</span>
        <span className="cf-pdf-button-text">&nbsp;&nbsp;{`${zoomLevel}%`}</span>
        <Button
          name="zoomOut"
          classNames={['cf-pdf-button cf-pdf-spaced-buttons-left']}
          onClick={setZoomOutLevel}
          disabled={disableZoomOut}
          ariaLabel="zoom out"
        >
          <i className="fa fa-minus" aria-hidden="true" />
        </Button>
        <Button
          name="zoomIn"
          classNames={['cf-pdf-button cf-pdf-spaced-buttons-left']}
          onClick={setZoomInLevel}
          disabled={disableZoomIn}
          ariaLabel="zoom in"
        >
          <i className="fa fa-plus" aria-hidden="true" />
        </Button>
        <Button
          name="zoomReset"
          classNames={['cf-pdf-button cf-pdf-spaced-buttons-left']}
          onClick={resetZoomLevel}
          ariaLabel="fit to screen"
        >
          <FitToScreenIcon />
        </Button>
        <Button
          name="rotation"
          classNames={['cf-pdf-button cf-pdf-spaced-buttons-left']}
          onClick={rotateDocument}
          ariaLabel="rotate document"
        >
          <RotateIcon />
        </Button>
        <span className="cf-pdf-spaced-buttons">|</span>
        <Button
          name="download"
          classNames={['cf-pdf-button cf-pdf-download-icon']}
          onClick={() => openDownloadLink(doc)}
          ariaLabel="download pdf"
        >
          <DownloadIcon />
        </Button>
        <Button
          name="search"
          classNames={['cf-pdf-button cf-pdf-search usa-search usa-search-small cf-pdf-spaced-buttons-left']}
          ariaLabel="search text"
          type="submit"
          onClick={onToggleSearchBar}
        >
          <SearchIcon />
        </Button>
        {hideSideBar && (
          <span {...pdfToolbarStyles.openSidebarMenu}>
            <Button
              name="open sidebar menu"
              classNames={['cf-pdf-button']}
              onClick={() => dispatch(togglePdfSidebar())}>
              <strong> Open menu </strong>
            </Button>
          </span>
        )}
      </div>
    </div>
  );
};

ReaderToolbar.propTypes = {
  documentPathBase: PropTypes.string,
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    filename: PropTypes.string,
    id: PropTypes.number,
    type: PropTypes.string,
  }),
  showClaimsLink: PropTypes.bool,
  resetZoomLevel: PropTypes.func,
  setZoomOutLevel: PropTypes.func,
  disableZoomOut: PropTypes.bool,
  setZoomInLevel: PropTypes.func,
  disableZoomIn: PropTypes.bool,
  zoomLevel: PropTypes.number,
  rotateDocument: PropTypes.func,
  hideSideBar: PropTypes.bool,
  toggleSearchBar: PropTypes.func,
  showSearchBar: PropTypes.bool,
};

export default ReaderToolbar;
