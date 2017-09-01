import React from 'react';
import PropTypes from 'prop-types';

import CommentLayer from './CommentLayer';
import { connect } from 'react-redux';
import _ from 'lodash';
import { setPdfPageDimensions } from '../reader/actions';
import { bindActionCreators } from 'redux';
import { pageNumberOfPageIndex } from './utils';

import classNames from 'classnames';

// This comes from the class .pdfViewer.singlePageView .page in _reviewer.scss.
// We need it defined here to be able to expand/contract margin between pages
// as we zoom.
const PAGE_MARGIN_BOTTOM = 25;

// These both come from _pdf_viewer.css and is the default height
// of the pages in the PDF. We need it defined here to be
// able to expand/contract the height of the pages as we zoom.
const PAGE_WIDTH = 816;
const PAGE_HEIGHT = 1056;

export class PdfPage extends React.Component {
  getPageContainerRef = (pageContainer) => {
    this.props.getPageContainerRef(this.props.pageIndex, this.props.docId, pageContainer);
  }
  getCanvasRef = (canvas) => {
    this.props.getCanvasRef(this.props.pageIndex, this.props.docId, canvas);
  }
  getTextLayerRef = (textLayer) => {
    this.props.getTextLayerRef(this.props.pageIndex, this.props.docId, textLayer);
  }

  getDimensions = () => {
    this.props.pdfDocument.getPage(pageNumberOfPageIndex(this.props.pageIndex)).then((pdfPage) => {
      const PAGE_DIMENSION_SCALE = 1;
      const viewport = pdfPage.getViewport(PAGE_DIMENSION_SCALE);
      const pageDimensions = _.pick(viewport, ['width', 'height']);

      this.props.setPdfPageDimensions(this.props.docId, this.props.pageIndex, pageDimensions);
    }).
    catch(() => {
      const pageDimensions = {
        width: PAGE_WIDTH,
        height: PAGE_HEIGHT
      };
      this.props.setPdfPageDimensions(this.props.docId, this.props.pageIndex, pageDimensions);
    });
  }

  componentDidMount = () => {
    this.getDimensions();
  }

  render() {
    const pageClassNames = classNames({
      'cf-pdf-pdfjs-container': true,
      page: true,
      'cf-pdf-placing-comment': this.props.isPlacingAnnotation
    });
    const currentWidth = _.get(this.props.pageDimensions, ['width'], PAGE_WIDTH);
    const currentHeight = _.get(this.props.pageDimensions, ['height'], PAGE_HEIGHT);

    const divPageStyle =  {
      marginBottom: `${PAGE_MARGIN_BOTTOM * this.props.scale}px`,
      width: `${this.props.scale * currentWidth}px`,
      height: `${this.props.scale * currentHeight}px`,
      verticalAlign: 'top',
      display: this.props.isVisible ? '' : 'none'
    };

    // Only pages that are the correct scale should be visible
    const CORRECT_SCALE_DELTA_THRESHOLD = 0.01;
    const pageContentsVisibleClass = classNames({
      'cf-pdf-page-hidden': !(Math.abs(this.props.scale - _.get(this.props.isDrawn,
          [this.props.docId, this.props.pageIndex, 'scale'])) < CORRECT_SCALE_DELTA_THRESHOLD)
    });

    return <div
      id={`${this.props.docId}-${this.props.pageIndex}`}
      className={pageClassNames}
      style={divPageStyle}
      ref={this.getPageContainerRef}>
        <div className={pageContentsVisibleClass}>
          <canvas
            ref={this.getCanvasRef}
            className="canvasWrapper" />
          <div className="cf-pdf-annotationLayer">
            {this.props.isVisible && <CommentLayer
              documentId={this.props.docId}
              pageIndex={this.props.pageIndex}
              scale={this.props.scale}
            />}
          </div>
          <div
            ref={this.getTextLayerRef}
            className="textLayer"/>
        </div>
      </div>;
  }
}

PdfPage.propTypes = {
  docId: PropTypes.string,
  pageIndex: PropTypes.number,
  isVisible: PropTypes.bool,
  scale: PropTypes.number,
  isDrawn: PropTypes.object,
  getPageContainerRef: PropTypes.func,
  getCanvasRef: PropTypes.func,
  getTextLayerRef: PropTypes.func,
  pdfDocument: PropTypes.object
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setPdfPageDimensions
  }, dispatch)
});

const mapStateToProps = (state, props) => ({
  pageDimensions: _.get(state.readerReducer, ['documents', props.docId, 'pages', props.pageIndex]),
  isPlacingAnnotation: state.readerReducer.ui.pdf.isPlacingAnnotation
});

export default connect(mapStateToProps, mapDispatchToProps)(PdfPage);
