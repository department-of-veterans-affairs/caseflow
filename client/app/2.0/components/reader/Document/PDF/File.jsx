// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { Grid, AutoSizer } from 'react-virtualized';

// Internal Dependencies
import { PAGE_MARGIN } from 'app/reader/constants';
import { Page } from 'components/reader/Document/PDF/Page';
import { gridStyles } from 'styles/reader/Document/Pdf';
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
      const numColumns = columnCount(width, props.pageWidth, props.numPages);

      return <div />;
      // return (
      //   <Grid
      //     // ref={gridRef}
      //     scrollTop={0}
      //     scrollLeft={0}
      //     containerStyle={gridStyles(props.isVisible)}
      //     // overscanIndicesGetter={overscanIndices}
      //     // estimatedRowSize={1}
      //     // overscanRowCount={Math.floor(windowingOverscan / numColumns)}
      //     // onScroll={scrollPage}
      //     height={height}
      //     rowCount={1}
      //     rowHeight={1}
      //     // cellRenderer={(cellProps) => (
      //     //   <Page
      //     //     outerHeight={clientHeight}
      //     //     outerWidth={clientWidth}
      //     //     numColumns={numColumns}
      //     //     {...cellProps}
      //     //     {...props}
      //     //   />
      //     // )}
      //     // scrollToAlignment="start"
      //     width={width}
      //     columnWidth={1}
      //     numColumns={1}
      //     // scale={props.scale}
      //     // tabIndex={props.isVisible ? 0 : -1}
      //   />
      // );
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
  numPages: PropTypes.number,
  pageWidth: PropTypes.number,
};
