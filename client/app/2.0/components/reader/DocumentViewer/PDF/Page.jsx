// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

// Internal Dependencies
import { Comments } from 'components/reader/DocumentViewer/Comments';
import { pageNumber } from 'utils/reader';
import { markStyles, pageStyles, pdfPageStyles } from 'styles/reader/Document/Pdf';
import { dimensions } from 'app/2.0/utils/reader/document';

/**
 * PDF Page Component
 * @param {Object} props -- Contains the PDF Page props and functions to manipulate the rotation/scale/dimensions
 */
export const Page = ({
  isPlacingAnnotation,
  scale,
  onClick,
  pageRef,
  canvasRef,
  currentDocument,
  setPageNumber,
  rotation,
  style,
  numPages,
  numColumns,
  rowIndex,
  columnIndex,
  ...props
}) => {
  // Calculate the Page Index
  const pageIndex = (numColumns * rowIndex) + columnIndex;

  // Calculate the page dimensions
  const { height, width } = dimensions(scale, rotation);

  return pageIndex >= numPages ? (
    <div key={(numColumns * rowIndex) + columnIndex} style={style} />
  ) : (
    <div key={pageIndex} style={style}>
      <div
        id={`pageContainer${pageNumber(pageIndex)}`}
        className={classNames({
          page: true,
          'cf-pdf-pdfjs-container': true,
          'cf-pdf-placing-comment': isPlacingAnnotation
        })}
        style={pageStyles({ width, height, scale })}
        onClick={onClick}
        ref={pageRef}
        {...markStyles}
      >
        <div
          id={`rotationDiv${pageNumber(pageIndex)}`}
          style={pdfPageStyles(rotation, height, width)}
        >
          <canvas id={`pdf-canvas-${pageIndex}`} ref={canvasRef} className="canvasWrapper" />
          <div className="cf-pdf-annotationLayer">
            {/* <Comments
              {...props}
              documentId={documentId}
              pageIndex={pageIndex}
              scale={scale}
              getTextLayerRef={textLayerRef}
              dimensions={{ width: innerWidth, height: innerHeight }}
              isVisible={isVisible}
            /> */}
          </div>
        </div>
      </div>
    </div>
  );
};

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
  currentDocument: PropTypes.object,
  innerWidth: PropTypes.number,
  innerHeight: PropTypes.number,
  isDrawing: PropTypes.bool,
  rotation: PropTypes.number,
  style: PropTypes.object,
  numPages: PropTypes.number,
  numColumns: PropTypes.number,
  rowIndex: PropTypes.number,
  columnIndex: PropTypes.number,
  setPageNumber: PropTypes.func
};
