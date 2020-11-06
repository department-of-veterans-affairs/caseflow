// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

// Internal Dependencies
import CommentLayer from 'app/reader/CommentLayer';
import { pageNumber } from 'utils/reader';
import { markStyles, pageStyles, pdfPageStyles } from 'styles/reader/Document/PDF';

/**
 * PDF Page Component
 * @param {Object} props -- Contains the PDF Page props and functions to manipulate the rotation/scale/dimensions
 */
export const Page = ({
  isVisible,
  pageIndex,
  isPlacingAnnotation,
  textLayerRef,
  outerWidth,
  outerHeight,
  scale,
  onClick,
  pageRef,
  canvasRef,
  documentId,
  file,
  innerWidth,
  innerHeight,
  isDrawing,
  rotation,
  style,
  pdfDocument,
  numColumns,
  rowIndex,
  columnIndex
}) => pageIndex >= pdfDocument.pdfInfo.numPages ? (
  <div key={(numColumns * rowIndex) + columnIndex} style={style} />
) : (
  <div key={pageIndex} style={style}>
    <div
      id={isVisible ? `pageContainer${pageNumber(pageIndex)}` : null}
      className={classNames({
        page: true,
        'cf-pdf-pdfjs-container': true,
        'cf-pdf-placing-comment': isPlacingAnnotation
      })}
      style={pageStyles({ width: outerWidth, height: outerHeight, scale, visible: isVisible })}
      onClick={onClick}
      ref={pageRef}
      {...markStyles}
    >
      <div
        id={isVisible && `rotationDiv${pageNumber(pageIndex)}`}
        className={classNames({ 'cf-pdf-page-hidden': isDrawing })}
        style={pdfPageStyles(rotation, outerHeight, outerWidth)}
      >
        <canvas ref={canvasRef} className="canvasWrapper" />
        <div className="cf-pdf-annotationLayer">
          <CommentLayer
            documentId={documentId}
            pageIndex={pageIndex}
            scale={scale}
            getTextLayerRef={textLayerRef}
            file={file}
            dimensions={{ width: innerWidth, height: innerHeight }}
            isVisible={isVisible}
          />
        </div>
      </div>
    </div>
  </div>
);

Page.propTypes = {
  isVisible: PropTypes.bool,
  pageIndex: PropTypes.number,
  isPlacingAnnotation: PropTypes.bool,
  textLayerRef: PropTypes.element,
  outerWidth: PropTypes.number,
  outerHeight: PropTypes.number,
  scale: PropTypes.number,
  onClick: PropTypes.func,
  pageRef: PropTypes.element,
  canvasRef: PropTypes.element,
  documentId: PropTypes.number,
  file: PropTypes.object,
  innerWidth: PropTypes.number,
  innerHeight: PropTypes.number,
  isDrawing: PropTypes.bool,
  rotation: PropTypes.number,
  style: PropTypes.object,
  pdfDocument: PropTypes.object,
  numColumns: PropTypes.number,
  rowIndex: PropTypes.number,
  columnIndex: PropTypes.number
};
