import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { pageNumberOfPageIndex } from './utils';
import PdfPage from './PdfPage';

// This comes from the class .pdfViewer.singlePageView .page in _reviewer.scss.
// We need it defined here to be able to expand/contract margin between pages
// as we zoom.
const PAGE_MARGIN_BOTTOM = 25;

// These both come from _pdf_viewer.css and is the default height
// of the pages in the PDF. We need it defined here to be
// able to expand/contract the height of the pages as we zoom.
const PAGE_WIDTH = 816;
const PAGE_HEIGHT = 1056;

// Under this maximum squared distance pages are drawn, beyond it they are not.
const MAX_SQUARED_DISTANCE = 10000000;
const NUMBER_OF_NON_VISIBLE_PAGES_TO_RENDER = 2;

export class PdfFile extends React.PureComponent {
  constructor(props) {
    super(props);

    this.isDrawing = false;
    this.isDrawn = false;
    this.previousShouldDraw = 0;
  }

  render() {
    return _.range(this.props.numPages).map((page, pageIndex) => <PdfPage
        scrollTop={this.props.scrollTop}
        scrollWindowCenter={this.props.scrollWindowCenter}
        documentId={this.props.documentId}
        key={`${file}-${pageIndex + 1}`}
        file={this.props.file}
        pageIndex={pageIndex}
        isVisible={this.props.isVisible}
        scale={this.props.scale}
        getPageContainerRef={this.props.getPageContainerRef}
        pdfDocument={this.props.pdfDocument}
      />;
  }
}

PdfFile.propTypes = {
  file:
  pdfDocument: PropTypes.object
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setUpPdfPage
  }, dispatch)
});

const mapStateToProps = (state, props) => {
};

export default connect(mapStateToProps, mapDispatchToProps)(PdfFile);
