// External Dependencies
import React, { useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

// Internal Dependencies
import { Comments } from 'components/reader/DocumentViewer/Comments';
import { pageNumber } from 'utils/reader';
import { markStyles, pdfPageStyles } from 'styles/reader/Document/PDF';
import { CommentSymbol } from 'app/components/RenderFunctions';
import { renderPage, renderText, renderContent } from 'utils/reader/pdf';
import ProgressBar from 'components/shared/ProgressBar';
import { LOGO_COLORS } from 'app/constants/AppConstants';

/**
 * PDF Page Component
 * @param {Object} props -- Contains the PDF Page props and functions to manipulate the rotation/scale/dimensions
 */
export const Page = ({
  addingComment,
  scale,
  pageRef,
  canvasRef,
  rotation,
  style,
  numColumns,
  rowIndex,
  columnIndex,
  moveComment,
  match,
  moveMouse,
  getCoords,
  currentPageIndex,
  pdf,
  ...props
}) => {
  // Calculate the Page Index
  const pageIndex = (numColumns * rowIndex) + columnIndex;
  const docId = match.params.docId;
  const page = props.pages[pageIndex];

  useEffect(() => {
    renderContent({ page, docId, scale, pageIndex, totalPages: props.overscanCount, setRenderError: props.handleError });
  }, [page, scale]);

  return pageIndex >= pdf?.numPages ? (
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
        ref={pageRef}
        {...markStyles}
      >
        <div id={`rotationDiv${pageNumber(pageIndex)}`} style={pdfPageStyles(rotation, style.height, style.width)}>
          <canvas id={`pdf-canvas-${docId}-${pageIndex}`} ref={canvasRef} className="canvasWrapper" />
          {addingComment && (
            <div
              id={`canvas-cursor-${pageIndex}`}
              className="commentIcon-container canvas-cursor"
              style={{
                position: 'absolute',
                display: pageIndex === currentPageIndex ? 'block' : 'none',
                left: '50%',
                top: '50%'
              }}
            >
              <CommentSymbol />
            </div>
          )}
          <div className="cf-pdf-annotationLayer">
            <Comments
              {...props}
              getCoords={getCoords}
              handleDrop={(event) => moveComment(getCoords(event, pageIndex), pageIndex)}
              moveMouse={(event) => moveMouse(getCoords(event, pageIndex), pageIndex)}
              currentDocument={pdf}
              documentId={docId}
              pageIndex={pageIndex}
              scale={scale}
              dimensions={{ width: style.width, height: style.height }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

Page.propTypes = {
  currentPageIndex: PropTypes.number,
  pageIndex: PropTypes.number,
  addingComment: PropTypes.bool,
  isVisible: PropTypes.bool,
  getCoords: PropTypes.func,
  moveComment: PropTypes.func,
  scale: PropTypes.number,
  pageRef: PropTypes.element,
  canvasRef: PropTypes.element,
  pdf: PropTypes.object,
  rotation: PropTypes.number,
  style: PropTypes.object,
  match: PropTypes.object,
  numPages: PropTypes.number,
  numColumns: PropTypes.number,
  rowIndex: PropTypes.number,
  columnIndex: PropTypes.number,
  setPageNumber: PropTypes.func,
  moveMouse: PropTypes.func,
  handleError: PropTypes.func,
  pages: PropTypes.array,
};
