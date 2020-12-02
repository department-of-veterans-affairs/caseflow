// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

// Internal Dependencies
import { Comments } from 'components/reader/DocumentViewer/Comments';
import { pageNumber, getPageCoordinatesOfMouseEvent } from 'utils/reader';
import { markStyles, pdfPageStyles } from 'styles/reader/Document/Pdf';
import { dimensions } from 'app/2.0/utils/reader/document';
import { commentIcon } from 'app/components/RenderFunctions';

/**
 * PDF Page Component
 * @param {Object} props -- Contains the PDF Page props and functions to manipulate the rotation/scale/dimensions
 */
export const Page = ({
  addingComment,
  scale,
  onClick,
  pageRef,
  canvasRef,
  currentDocument,
  rotation,
  style,
  numPages,
  numColumns,
  rowIndex,
  columnIndex,
  dropComment,
  movingComment,
  moveComment,
  ...props
}) => {
  // Calculate the Page Index
  const pageIndex = (numColumns * rowIndex) + columnIndex;

  // Calculate the page dimensions
  const { height, width } = dimensions(scale, rotation);

  // Create the Click handler for dropping comments
  const handleClick = (event) => {
    event.stopPropagation();
    const coords = getPageCoordinatesOfMouseEvent(
      event,
      document.getElementById(`comment-layer-${pageIndex}`).getBoundingClientRect(),
      scale,
      currentDocument.rotation
    );

    // Drop the comment at the coordinates
    if (addingComment) {
      dropComment({
        document_id: currentDocument.id,
        pendingComment: '',
        id: 'placing-annotation-icon',
        page: pageIndex + 1,
        x: coords.x,
        y: coords.y,
      });
    }
  };

  const handleDrop = (event) => {
    const coords = getPageCoordinatesOfMouseEvent(
      event,
      document.getElementById(`comment-layer-${pageIndex}`).getBoundingClientRect(),
      scale,
      currentDocument.rotation
    );

    moveComment({
      document_id: currentDocument.id,
      id: movingComment,
      x: coords.x,
      y: coords.y,
    });
  };

  const moveMouse = (event) => {
    if (addingComment) {
      const coords = getPageCoordinatesOfMouseEvent(
        event,
        document.getElementById(`comment-layer-${pageIndex}`).getBoundingClientRect(),
        scale,
        currentDocument.rotation
      );

      // Move the cursor icon
      const cursor = document.getElementById('canvas-cursor');

      // Update the coordinates
      cursor.style.left = `${coords.x}px`;
      cursor.style.top = `${coords.y}px`;

    }
  };

  return pageIndex >= numPages ? (
    <div key={(numColumns * rowIndex) + columnIndex} style={style} />
  ) : (
    <div key={pageIndex} style={style} >
      <div
        id={`pageContainer${pageNumber(pageIndex)}`}
        className={classNames({
          page: true,
          'cf-pdf-pdfjs-container': true,
          'cf-pdf-placing-comment': addingComment
        })}
        onClick={onClick}
        ref={pageRef}
        {...markStyles}
      >
        <div id={`rotationDiv${pageNumber(pageIndex)}`} style={pdfPageStyles(rotation, height, width)}>
          <canvas id={`pdf-canvas-${currentDocument.id}-${pageIndex}`} ref={canvasRef} className="canvasWrapper" />
          {addingComment && <div id="canvas-cursor" style={{ position: 'absolute' }}>{commentIcon()}</div>}
          <div className="cf-pdf-annotationLayer">
            <Comments
              {...props}
              handleDrop={handleDrop}
              dropComment={dropComment}
              movingComment={movingComment}
              moveMouse={moveMouse}
              onClick={handleClick}
              currentDocument={currentDocument}
              documentId={currentDocument.id}
              pageIndex={pageIndex}
              scale={scale}
              dimensions={{ width, height }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

Page.propTypes = {
  pageIndex: PropTypes.number,
  addingComment: PropTypes.bool,
  dropComment: PropTypes.func,
  movingComment: PropTypes.bool,
  moveComment: PropTypes.func,
  scale: PropTypes.number,
  onClick: PropTypes.func,
  pageRef: PropTypes.element,
  canvasRef: PropTypes.element,
  currentDocument: PropTypes.object,
  rotation: PropTypes.number,
  style: PropTypes.object,
  numPages: PropTypes.number,
  numColumns: PropTypes.number,
  rowIndex: PropTypes.number,
  columnIndex: PropTypes.number,
  setPageNumber: PropTypes.func
};
