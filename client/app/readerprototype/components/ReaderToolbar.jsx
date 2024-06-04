import PropTypes from 'prop-types';
import React from 'react';

import Button from '../../components/Button';
import Link from '../../components/Link';
import { DownloadIcon } from '../../components/icons/DownloadIcon';
import { ExternalLinkIcon } from '../../components/icons/ExternalLinkIcon';
import { FitToScreenIcon } from '../../components/icons/FitToScreenIcon';
import { LeftChevronIcon } from '../../components/icons/LeftChevronIcon';
import { RotateIcon } from '../../components/icons/RotateIcon';
import { SearchIcon } from '../../components/icons/SearchIcon';
import DocumentCategoryIcons from '../../reader/DocumentCategoryIcons';

import { handleClickDocumentTypeLink, openDownloadLink } from '../documentUtil';
import { docToolbarStyles } from '../layoutUtil';

const ReaderToolbar = ({
  resetZoomLevel,
  documentPathBase,
  doc,
  showClaimsFolderNavigation,
  setZoomOutLevel,
  disableZoomOut,
  setZoomInLevel,
  disableZoomIn,
  zoomLevel,
  rotateDocument
  // hideSidebar,
  // toggleSidebar
}) => {
  return <>
    <div {...docToolbarStyles.toolbar} {...docToolbarStyles.toolbarLeft}>
      {showClaimsFolderNavigation && (
        <Link
          to={`${documentPathBase}`}
          name="backToClaimsFolder"
          button="matte"
        >
          <LeftChevronIcon /> &nbsp; Back
        </Link>
      )}
    </div>
    <div {...docToolbarStyles.toolbar} {...docToolbarStyles.toolbarCenter}>
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
            href={window.location.pathname.includes('prototype') ?
            `/reader/appeal${documentPathBase}/${doc.id}/prototype` :
            `/reader/appeal${documentPathBase}/${doc.id}`}
          >
            <h1 className="cf-pdf-vertically-center cf-non-stylized-header">
              <span title="Open in new tab">{doc.type}</span>
              <span className="cf-pdf-external-link-icon"><ExternalLinkIcon /></span>
            </h1>
          </Link>
        </span>
      </span>
    </div>
    <div {...docToolbarStyles.toolbar} {...docToolbarStyles.toolbarRight}>
      <span className="cf-pdf-button-text">Zoom:</span>
      <span className="cf-pdf-button-text">&nbsp;&nbsp;{ `${zoomLevel}%` }</span>
      <Button
        name="zoomOut"
        classNames={['cf-pdf-button cf-pdf-spaced-buttons-left']}
        onClick={() => setZoomOutLevel()}
        disabled={disableZoomOut}
        ariaLabel="zoom out">
        <i className="fa fa-minus" aria-hidden="true" />
      </Button>
      <Button
        name="zoomIn"
        classNames={['cf-pdf-button cf-pdf-spaced-buttons-left']}
        onClick={() => setZoomInLevel()}
        disabled={disableZoomIn}
        ariaLabel="zoom in">
        <i className="fa fa-plus" aria-hidden="true" />
      </Button>
      <Button
        name="zoomReset"
        classNames={['cf-pdf-button cf-pdf-spaced-buttons-left']}
        onClick={() => resetZoomLevel()}
        ariaLabel="fit to screen">
        <FitToScreenIcon />
      </Button>
      <Button
        name="rotation"
        classNames={['cf-pdf-button cf-pdf-spaced-buttons-left']}
        onClick={() => rotateDocument()}
        ariaLabel="rotate document">
        <RotateIcon />
      </Button>
      <span className="cf-pdf-spaced-buttons">|</span>
      <Button
        name="download"
        classNames={['cf-pdf-button cf-pdf-download-icon']}
        onClick={() => openDownloadLink(doc)}
        ariaLabel="download pdf">
        <DownloadIcon />
      </Button>
      <Button
        name="search"
        classNames={['cf-pdf-button cf-pdf-search usa-search usa-search-small cf-pdf-spaced-buttons-left']}
        ariaLabel="search text"
        type="submit"
        disabled
        // onClick={toggleSearchBar()}
      >
        <SearchIcon />
      </Button>
      {/* {hideSidebar &&
        (<span {...docToolbarStyles.openSidebarMenu}>
          <Button
            name="open sidebar menu"
            classNames={['cf-pdf-button']}
            onClick={() => toggleSidebar()}>
            <strong> Open menu </strong>
          </Button>
        </span>)
      } */}
    </div>
  </>;
};

ReaderToolbar.propTypes = {
  documentPathBase: PropTypes.string,
  doc: PropTypes.object,
  showClaimsFolderNavigation: PropTypes.bool,
  resetZoomLevel: PropTypes.func,
  setZoomOutLevel: PropTypes.func,
  disableZoomOut: PropTypes.bool,
  setZoomInLevel: PropTypes.func,
  disableZoomIn: PropTypes.bool,
  zoomLevel: PropTypes.number,
  rotateDocument: PropTypes.func,
  hideSidebar: PropTypes.bool,
  toggleSidebar: PropTypes.func,
};

export default ReaderToolbar;
