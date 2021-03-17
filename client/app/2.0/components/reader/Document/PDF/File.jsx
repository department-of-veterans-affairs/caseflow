// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { Grid, AutoSizer } from 'react-virtualized';

// Internal Dependencies
import { PAGE_MARGIN } from 'app/reader/constants';
import { Page } from 'components/reader/Document/PDF/Page';
import { gridStyles } from 'styles/reader/Document/PDF';
import { columnCount } from 'app/2.0/utils/reader';

/**
 * PDF File Component
 * @param {Object} props
 */
export const File = ({
  clientHeight,
  clientWidth,
  gridRef,
  overscanIndices,
  pageHeight,
  windowingOverscan,
  scrollPage,
  rowHeight,
  columnWidth,
  ...props
}) => (
  <AutoSizer>
    {({ width, height }) => {
      // Calculate the column count
      const numColumns = columnCount(width, props.pageWidth, props.pdfDocument.pdfInfo.numPages);

      return (
        <Grid
          ref={gridRef}
          containerStyle={gridStyles(props.isVisible)}
          overscanIndicesGetter={overscanIndices}
          estimatedRowSize={(pageHeight(0) + PAGE_MARGIN) * props.scale}
          overscanRowCount={Math.floor(windowingOverscan / numColumns)}
          onScroll={scrollPage}
          height={height}
          rowCount={Math.ceil(props.pdfDocument.pdfInfo.numPages / numColumns)}
          rowHeight={rowHeight}
          cellRenderer={(cellProps) => (
            <Page
              outerHeight={clientHeight}
              outerWidth={clientWidth}
              numColumns={numColumns}
              {...cellProps}
              {...props}
            />
          )}
          scrollToAlignment="start"
          width={width}
          columnWidth={columnWidth}
          numColumns={numColumns}
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
  gridRef: PropTypes.element,
  overscanIndices: PropTypes.number,
  pageHeight: PropTypes.func,
  windowingOverscan: PropTypes.number,
  scrollPage: PropTypes.func,
  rowHeight: PropTypes.number,
  columnWidth: PropTypes.number,
  scale: PropTypes.number,
  isVisible: PropTypes.bool,
  pdfDocument: PropTypes.object,
  pageWidth: PropTypes.number,
};
