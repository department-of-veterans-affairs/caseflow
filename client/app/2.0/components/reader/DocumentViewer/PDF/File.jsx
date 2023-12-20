// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { Grid, AutoSizer } from 'react-virtualized';

// Internal Dependencies
import { Page } from 'components/reader/DocumentViewer/PDF/Page';
import { gridStyles } from 'styles/reader/Document/PDF';
import { columnWidth, rowHeight, columnCount } from 'utils/reader';
import { PAGE_MARGIN } from 'app/2.0/store/constants/reader';

/**
 * PDF File Component
 * @param {Object} props
 */
export const File = ({ gridRef, overscanIndices, windowingOverscan, scrollPage, viewport, ...props }) => (
  <AutoSizer>
    {({ width, height }) => {
      // Set the Page Width
      const pageWidth = columnWidth({
        horizontal: [90, 270].includes(props.currentDocument.rotation),
        numPages: props.currentDocument.numPages,
        dimensions: viewport
      });

      // Calculate the column count
      const numColumns = columnCount(width, pageWidth, props.currentDocument.numPages) || 1;

      // Calculate the count of rows
      const rowCount = Math.ceil(props.currentDocument.numPages / numColumns) || 1;

      // Calculate the page height
      const pageHeight = rowHeight({
        horizontal: [90, 270].includes(props.currentDocument.rotation),
        dimensions: viewport,
        numPages: props.currentDocument.numPages
      });

      return (
        <Grid
          id="canvas-grid"
          ref={gridRef}
          containerStyle={gridStyles(props.isVisible)}
          overscanIndicesGetter={overscanIndices}
          estimatedRowSize={(viewport.height + PAGE_MARGIN) * props.scale}
          overscanRowCount={Math.floor(windowingOverscan / numColumns)}
          onScroll={scrollPage}
          height={height}
          rowCount={rowCount}
          rowHeight={pageHeight}
          cellRenderer={(cellProps) => (
            <Page
              {...cellProps}
              {...props}
              gridRef={gridRef}
              outerHeight={height}
              outerWidth={width}
              numColumns={numColumns}
              rotation={props.currentDocument.rotation}
            />
          )}
          scrollToAlignment="start"
          width={width}
          columnWidth={pageWidth}
          columnCount={numColumns}
          scale={props.scale}
          tabIndex={props.isVisible ? 0 : -1}
        />
      );
    }}
  </AutoSizer>
);

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
  currentDocument: PropTypes.object,
  viewport: PropTypes.object,
};
