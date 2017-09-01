import React from 'react';
import PropTypes from 'prop-types';

import CommentLayer from './CommentLayer';
import { connect } from 'react-redux';
import _ from 'lodash';

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
    this.props.getPageContainerRef(this.props.pageIndex, this.props.file, pageContainer);
  }
  getCanvasRef = (canvas) => {
    this.props.getCanvasRef(this.props.pageIndex, this.props.file, canvas);
  }
  getTextLayerRef = (textLayer) => {
    this.props.getTextLayerRef(this.props.pageIndex, this.props.file, textLayer);
  }

  render() {
    const divPageStyle =  {
      marginBottom: `${PAGE_MARGIN_BOTTOM * this.props.scale}px`,
      width: `${this.props.scale * currentWidth}px`,
      height: `${this.props.scale * currentHeight}px`,
      verticalAlign: 'top',
      display: this.props.isVisible ? '' : 'none'
    };
    const pageClassNames = classNames({
      'cf-pdf-pdfjs-container': true,
      page: true,
      'cf-pdf-placing-comment': this.props.isPlacingAnnotation
    });
    const currentWidth = _.get(this.props.pageDimensions,
      [this.props.file, this.props.pageIndex, 'width'], PAGE_WIDTH);
    const currentHeight = _.get(this.props.pageDimensions,
      [this.props.file, this.props.pageIndex, 'height'], PAGE_HEIGHT);

    // Only pages that are the correct scale should be visible
    const CORRECT_SCALE_DELTA_THRESHOLD = 0.01;
    const pageContentsVisibleClass = classNames({
      'cf-pdf-page-hidden': !(Math.abs(this.props.scale - _.get(this.props.isDrawn,
          [this.props.file, this.props.pageIndex, 'scale'])) < CORRECT_SCALE_DELTA_THRESHOLD)
    });

    return <div
      id={`${this.props.file}-${this.props.pageIndex}`}
      className={pageClassNames}
      style={divPageStyle}
      ref={this.getPageContainerRef}>
        <div className={pageContentsVisibleClass}>
          <canvas
            ref={this.getCanvasRef}
            className="canvasWrapper" />
          <div className="cf-pdf-annotationLayer">
            {this.props.isVisible && <CommentLayer
              documentId={this.props.documentId}
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
  documentId: PropTypes.documentId,
  file: PropTypes.string,
  pageIndex: PropTypes.number,
  isVisible: PropTypes.bool,
  scale: PropTypes.number,
  pageDimensions: PropTypes.object,
  isDrawn: PropTypes.object,
  getPageContainerRef: PropTypes.func,
  getCanvasRef: PropTypes.func,
  getTextLayerRef: PropTypes.func
};

const mapStateToProps = (state) => ({
  ..._.pick(state.readerReducer.ui, 'selectedAnnotationId'),
  isPlacingAnnotation: state.readerReducer.ui.pdf.isPlacingAnnotation
});

export default connect(mapStateToProps)(PdfPage);
