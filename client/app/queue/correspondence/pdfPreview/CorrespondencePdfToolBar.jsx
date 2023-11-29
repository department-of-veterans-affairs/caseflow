import { css } from 'glamor';
import { map, size, sortBy } from 'lodash';
import React from 'react';
import PropTypes from 'prop-types';
import Link from '../../../components/Link';
import { ExternalLinkIcon } from '../../../components/icons/ExternalLinkIcon';
import Button from '../../../components/Button';
import { RotateIcon } from '../../../components/icons/RotateIcon';
import { FitToScreenIcon } from '../../../components/icons/FitToScreenIcon';
import { DownloadIcon } from '../../../components/icons/DownloadIcon';
import { SearchIcon } from '../../../components/icons/SearchIcon';
import { categoryFieldNameOfCategoryName } from '../../../reader/utils';
import * as Constants from '../../../reader/constants';

const CorrespondencePdfToolBar = (props) => {
  const {
    doc,
    documentPathBase,
    zoomIn,
    zoomOut,
    fitToScreen,
    handleDocumentRotation,
    handleSearchBarToggle
  } = props;

  // In-Line CSS Styles
  // PDF Document Viewer is 800px wide or less.
  const pdfWrapperSmall = 1165;
  const pdfToolbarStyles = {
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

  // Downlaod
  const openDownloadLink = () => {
    window.open(`${doc.content_url}?type=${doc.type}&download=true`);
  };

  return (
    <div className="cf-pdf-preview-header cf-pdf-toolbar">
      <span {...pdfToolbarStyles.toolbar} {...pdfToolbarStyles.toolbarCenter}>
        <span className="category-icons-and-doc-type">
          <span className="cf-pdf-doc-category-icons">
            <CorrespondenceDocumentCategoryIcons doc={doc} />
          </span>
          <span className="cf-pdf-preview-doc-type-button-container">
            <Link
              name="newTab"
              ariaLabel="open document in new tab"
              target="_blank"
              button="matte"
              href={`/reader/appeal${documentPathBase}/${doc.id}`}>
              <h1 className="cf-pdf-vertically-center cf-non-stylized-header">
                <span title="Open in new tab">{doc.type}</span>
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
          onClick={zoomOut}
          ariaLabel="zoom out">
          <i className="fa fa-minus" aria-hidden="true" />
        </Button>
        <Button
          name="zoomIn"
          classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
          onClick={zoomIn}
          ariaLabel="zoom in">
          <i className="fa fa-plus" aria-hidden="true" />
        </Button>
        <Button
          name="fit"
          classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
          onClick={fitToScreen}
          ariaLabel="fit to screen">
          <FitToScreenIcon />
        </Button>
        {/* <Button
          name="rotation"
          classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
          onClick={handleDocumentRotation}
          ariaLabel="rotate document">
          <RotateIcon />
        </Button> */}
        <span className="cf-pdf-spaced-buttons">|</span>
        <Button
          name="download"
          classNames={['cf-pdf-button cf-pdf-download-icon']}
          onClick={openDownloadLink}
          ariaLabel="download pdf">
          <DownloadIcon />
        </Button>
        {/* <Button
          name="search"
          classNames={['cf-pdf-button cf-pdf-search usa-search usa-search-small']}
          ariaLabel="search text"
          type="submit"
          onClick={handleSearchBarToggle}>
          <SearchIcon />
        </Button> */}
      </span>
    </div>
  );
};

const CorrespondenceDocumentCategoryIcons = ({ doc }) => {

  // Helper function
  const categoriesOfDocument = (document) =>
    sortBy(
      Object.keys(Constants.documentCategories).reduce((list, name) => {
        if (document[categoryFieldNameOfCategoryName(name)]) {
          return {
            ...list,
            [name]: Constants.documentCategories[name]
          };
        }

        return list;
      }, {}),
      'renderOrder'
    );

  const categories = categoriesOfDocument(doc);

  if (!size(categories)) {
    return null;
  }
  const listClassName = 'cf-no-styling-list';

  return (
    <ul className="cf-document-category-icons" aria-label="document categories">
      {map(categories, (category) => (
        <li
          className={listClassName}
          key={category.renderOrder}
          aria-label={category.humanName}
        >
          {category.svg}
        </li>
      ))}
    </ul>
  );
};

CorrespondenceDocumentCategoryIcons.propTypes = {
  doc: PropTypes.object.isRequired,
};

export default CorrespondencePdfToolBar;
