import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import Button from '../components/Button';
import Link from '../components/Link';

import { DownloadIcon } from '../components/icons/DownloadIcon';
import { LeftChevronIcon } from '../components/icons/LeftChevronIcon';
import { ExternalLinkIcon } from '../components/icons/ExternalLinkIcon';
import { FitToScreenIcon } from '../components/icons/FitToScreenIcon';
import { RotateIcon } from '../components/icons/RotateIcon';
import { SearchIcon } from '../components/icons/SearchIcon';
import DocumentCategoryIcons from '../reader/DocumentCategoryIcons';

const pdfWrapperSmall = 1165;

const pdfToolbarStyles = {
  openSidebarMenu: css({ marginRight: '2%' }),
  toolbar: css({ width: '33%' }),
  toolbarLeft: css({
    '&&': { [`@media(max-width:${pdfWrapperSmall}px)`]: {
      width: '18%' }
    }
  }),
  toolbarCenter: css({
    '&&': { [`@media(max-width:${pdfWrapperSmall}px)`]: {
      width: '24%' }
    }
  }),
  toolbarRight: css({
    textAlign: 'right',
    '&&': { [`@media(max-width:${pdfWrapperSmall}px)`]: {
      width: '44%',
      '& .cf-pdf-button-text': { display: 'none' } }
    }
  }),
  footer: css({
    position: 'absolute',
    bottom: 0,
    display: 'flex',
    alignItems: 'center',
    '&&': { [`@media(max-width:${pdfWrapperSmall}px)`]: {
      '& .left-button-label': { display: 'none' },
      '& .right-button-label': { display: 'none' }
    } }
  })
};
const openDownloadLink = (doc) => {
  window.open(`${doc.content_url}?type=${doc.docType}&download=true`);
};

const ReaderToolbar = ({
  documentPathBase,
  doc,
  showClaimsFolderNavigation
}) => {
  return <>
    <span {...pdfToolbarStyles.toolbar} {...pdfToolbarStyles.toolbarLeft}>
      {showClaimsFolderNavigation && (
        <Link
          to={`${documentPathBase}`}
          name="backToClaimsFolder"
          button="matte"
        >
          <LeftChevronIcon /> &nbsp; Back
        </Link>
      )}
    </span>

    <span style={{ color: '#cc0000', fontWeight: 600 }}> PROTOTYPE!!!!! </span>

    <span {...pdfToolbarStyles.toolbar} {...pdfToolbarStyles.toolbarCenter}>
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
            // onClick={handleClickDocumentTypeLink}
            href={`/reader/appeal${documentPathBase}/${doc.id}`}>
            <h1 className="cf-pdf-vertically-center cf-non-stylized-header">
              <span title="Open in new tab">{doc.docType}</span>
              <span className="cf-pdf-external-link-icon"><ExternalLinkIcon /></span>
            </h1>
          </Link>
        </span>
      </span>
    </span>
    <span {...pdfToolbarStyles.toolbar} {...pdfToolbarStyles.toolbarRight}>
      <span className="cf-pdf-button-text">Zoom:</span>
      <Button
        name="zoomOut"
        classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
        // onClick={() => setZoomLevel(zoomLevel - 10)}
        ariaLabel="zoom out">
        <i className="fa fa-minus" aria-hidden="true" />
      </Button>
      <Button
        name="zoomIn"
        classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
        // onClick={() => setZoomLevel(zoomLevel + 10)}
        ariaLabel="zoom in">
        <i className="fa fa-plus" aria-hidden="true" />
      </Button>
      <Button
        name="fit"
        classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
        // onClick={this.fitToScreen}
        ariaLabel="fit to screen">
        <FitToScreenIcon />
      </Button>
      <Button
        name="rotation"
        classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
        // onClick={rotateDocument}
        ariaLabel="rotate document">
        <RotateIcon />
      </Button>
      <span className="cf-pdf-spaced-buttons">|</span>
      <Button
        name="download"
        classNames={['cf-pdf-button cf-pdf-download-icon']}
        onClick={openDownloadLink(doc)}
        ariaLabel="download pdf">
        <DownloadIcon />
      </Button>
      <Button
        name="search"
        classNames={['cf-pdf-button cf-pdf-search usa-search usa-search-small']}
        ariaLabel="search text"
        // onClick={props.toggleSearchBar}
        type="submit">
        <SearchIcon />
      </Button>
    </span>
  </>;
};

ReaderToolbar.propTypes = {
  documentPathBase: PropTypes.string,
  doc: PropTypes.object,
  showClaimsFolderNavigation: PropTypes.bool
};

export default ReaderToolbar;
