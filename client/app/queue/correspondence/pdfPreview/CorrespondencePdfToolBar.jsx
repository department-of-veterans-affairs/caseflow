import React from 'react';
import PropTypes from 'prop-types';
import Link from '../../../components/Link';
import { ExternalLinkIcon } from '../../../components/icons/ExternalLinkIcon';
import Button from '../../../components/Button';
import { RotateIcon } from '../../../components/icons/RotateIcon';
import { FitToScreenIcon } from '../../../components/icons/FitToScreenIcon';

const CorrespondencePdfToolBar = (props) => {
  const {
    doc,
    documentPathBase,
    zoomIn,
    zoomOut,
    fitToScreen,
    handleDocumentRotation
  } = props;

  return (
    <div className="cf-pdf-preview-header cf-pdf-toolbar">
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
      <span className="correspondence-pdf-tool-bar toolbar-right">
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
        <Button
          name="rotation"
          classNames={['cf-pdf-button cf-pdf-spaced-buttons']}
          onClick={handleDocumentRotation}
          ariaLabel="rotate document">
          <RotateIcon />
        </Button>
      </span>
    </div>
  );
};

CorrespondencePdfToolBar.propTypes = {
  doc: PropTypes.object,
  documentPathBase: PropTypes.string,
  zoomIn: PropTypes.func,
  zoomOut: PropTypes.func,
  fitToScreen: PropTypes.func,
  handleDocumentRotation: PropTypes.func,
};

export default CorrespondencePdfToolBar;
