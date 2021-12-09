// External Dependencies
import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Grid, AutoSizer } from 'react-virtualized';
import { isEmpty } from 'lodash';

// Internal Dependencies
import { Page } from 'components/reader/DocumentViewer/PDF/Page';
import { PAGE_MARGIN, DEFAULT_VIEWPORT } from 'app/2.0/store/constants/reader';
import { gridStyles, pdfStyles, fileContainerStyles } from 'styles/reader/Document/PDF';
import StatusMessage from 'app/components/StatusMessage';
import { columnWidth, rowHeight, columnCount, keyHandler, formatCommentQuery, focusComment } from 'utils/reader';
import { renderPdf } from 'utils/reader/pdf';

export const LoadError = ({ pdf }) => (
  <div>
    <div style={pdfStyles}>
      <StatusMessage title="Unable to load document" type="warning">
        Caseflow is experiencing technical difficulties and cannot load{' '}
        <strong>{pdf?.type}</strong>.
        <br />
        You can try{' '}
        <a href={`${pdf?.content_url}?type=${pdf?.type}&download=true`}>
          downloading the document
        </a>
        or try again later.
      </StatusMessage>
    </div>
  </div>
);

LoadError.propTypes = {
  pdf: PropTypes.object,
};

const RenderOverlay = ({ height, width }) => (
  <div style={{ height, width, backgroundColor: '#000', opacity: 0.5, position: 'absolute', top: 0, zIndex: 10000 }} />
);

/**
 * PDF File Component
 * @param {Object} props
 */
export const File = ({
  gridRef,
  overscanIndices,
  scrollPage,
  ...props
}) => {
  const [pages, setPages] = useState([]);
  const [loadError, setRenderError] = useState(props.loadError);

  const handleError = () => {
    props.setRendering(false);
    setRenderError(true);
  };

  // Load the Documents
  useEffect(() => {
    renderPdf({ pdf: props.pdf, setPages, setRenderError });

    return () => props.setRendering(true);
  }, [props.pdf]);
  // useEffect(() => {
  //   // Parse the annotation ID
  //   const commentId = formatCommentQuery();

  //   // Determine if there is a comment in the URL
  //   const commentQuery = props.comments.length && commentId;

  //   // Instantiate the comment object
  //   const selectedComment = commentQuery ?
  //     props.comments.filter((item) => item.id === commentId)[0] :
  //     props.selectedComment;

  //   // Handle the `JumpToComment` feature
  //   if (!isEmpty(selectedComment)) {
  //     // Scroll the DOM to the selected comment
  //     focusComment(selectedComment);

  //     // Update the Page number so that `react-virtualized` resizes the window
  //     // props.setPageNumber(selectedComment.page - 1);

  //     // Ensure the comment is selected in the store
  //     props.selectComment(selectedComment);
  //   }

  //   // Create the Keyboard Listener
  //   const listener = (event) => keyHandler(event, props);

  //   // Attach the key listener
  //   document.addEventListener('keydown', listener);

  //   // Remove the key listener when the component is unmounted
  //   return () => document.removeEventListener('keydown', listener);
  // }, [
  //   props.currentPageIndex,
  //   props.currentDocument?.id,
  //   props.search,
  //   props.selectedComment,
  //   props.hideSearchBar,
  //   props.addingComment,
  //   props.droppedComment,
  //   props.editingComment,
  //   props.editingTag
  // ]);

  return (
    <div className="cf-pdf-scroll-view" style={{ marginTop: 10 }}>
      {props.rendering && <RenderOverlay />}
      {Boolean(pages.length) && (
        <div id={props.pdf?.content_url} style={fileContainerStyles} onClick={props.clickPage}>
          {loadError ? <LoadError pdf={props.pdf} /> : (
            <AutoSizer>
              {({ width, height }) => {
                const viewport = pages?.length && pages[0]?.getViewport ? pages[0].getViewport({ scale: props.scale }) : DEFAULT_VIEWPORT;

                // Set the Page Width
                const pageWidth = columnWidth({
                  horizontal: [90, 270].includes(props.rotation),
                  numPages: props.pdf?.numPages,
                  dimensions: viewport,
                });

                // Calculate the column count
                const numColumns = columnCount(width, pageWidth, props.pdf?.numPages) || 1;

                // Calculate the count of rows
                const rowCount = Math.ceil(props.pdf?.numPages / numColumns) || 1;

                // Calculate the page height
                const pageHeight = rowHeight({
                  horizontal: [90, 270].includes(props.rotation),
                  dimensions: viewport,
                  numPages: props.pdf?.numPages,
                });

                const overscanCount = Math.floor(props.windowingOverscan / numColumns);

                return (
                  <React.Fragment>
                    {/* {rendering && <RenderOverlay height={height} width={width} />} */}
                    <Grid
                      id="canvas-grid"
                      ref={gridRef}
                      containerStyle={gridStyles(props.isVisible)}
                      overscanIndicesGetter={overscanIndices}
                      estimatedRowSize={(viewport.height + PAGE_MARGIN) * props.scale}
                      overscanRowCount={overscanCount}
                      onScroll={scrollPage}
                      height={height}
                      rowCount={rowCount}
                      rowHeight={pageHeight}
                      cellRenderer={(cellProps) => (
                        <Page
                          {...cellProps}
                          {...props}
                          handleError={handleError}
                          overscanCount={overscanCount}
                          pages={pages}
                          gridRef={gridRef}
                          outerHeight={height}
                          outerWidth={width}
                          numColumns={numColumns}
                          rotation={props.rotation}
                        />
                      )}
                      scrollToAlignment="start"
                      width={width}
                      columnWidth={pageWidth}
                      columnCount={numColumns}
                      scale={props.scale}
                      tabIndex={props.isVisible ? 0 : -1}
                    />
                  </React.Fragment>
                );
              }}
            </AutoSizer>
          )}
        </div>
      )}
    </div>
  );
};

File.propTypes = {
  clientHeight: PropTypes.number,
  clientWidth: PropTypes.number,
  gridRef: PropTypes.object,
  overscanIndices: PropTypes.func,
  pageHeight: PropTypes.func,
  windowingOverscan: PropTypes.string,
  scrollPage: PropTypes.func,
  rowHeight: PropTypes.number,
  columnWidth: PropTypes.number,
  scale: PropTypes.number,
  isVisible: PropTypes.bool,
  numPages: PropTypes.number,
  pageWidth: PropTypes.number,
  pdf: PropTypes.object,
  viewport: PropTypes.object,
};
