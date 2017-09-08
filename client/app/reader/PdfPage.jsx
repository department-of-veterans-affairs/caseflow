import React from 'react';
import PropTypes from 'prop-types';

import CommentLayer from './CommentLayer';
import { connect } from 'react-redux';
import _ from 'lodash';
import { setPdfPageDimensions, setIfPdfPageIsDrawn, setIfPdfPageIsDrawing } from '../reader/actions';
import { bindActionCreators } from 'redux';
import { pageNumberOfPageIndex } from './utils';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

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
  constructor(props) {
    super(props);

    this.isDrawing = false;
  }
  getPageContainerRef = (pageContainer) => {
    this.pageContainer = pageContainer;
    this.props.getPageContainerRef(this.props.pageIndex, this.props.file, pageContainer);
  }

  getCanvasRef = (canvas) => {
    this.canvas = canvas;
  }

  getTextLayerRef = (textLayer) => {
    this.textLayer = textLayer;
  }

  setIsDrawing = (value) => {
    this.props.setIfPdfPageIsDrawing(this.props.file, this.props.pageIndex, value);
    this.isDrawing = value;
  }

  // This method is the interaction between our component and PDFJS.
  // When this method resolves the returned promise it means the PDF
  // has been drawn with the most up to date scale passed in as a prop.
  // We may execute multiple draws to ensure this property.
  drawPage = () => {
    if (this.isDrawing) {
      return Promise.reject();
    }
    const currentScale = this.props.scale;

    this.setIsDrawing(true);
    return this.props.pdfDocument.getPage(pageNumberOfPageIndex(this.props.pageIndex)).then((pdfPage) => {
      // The viewport is a PDFJS concept that combines the size of the
      // PDF pages with the scale go get the dimensions of the divs.
      const viewport = pdfPage.getViewport(this.props.scale);

      // We need to set the width and heights of everything based on
      // the width and height of the viewport.
      this.canvas.height = viewport.height;
      this.canvas.width = viewport.width;

      this.textLayer.innerHTML = '';

      // Call PDFJS to actually draw the page.
      return pdfPage.render({
        canvasContext: this.canvas.getContext('2d', { alpha: false }),
        viewport
      }).
      then(() => {
        return Promise.resolve({
          pdfPage,
          viewport
        });
      });
    }).
    then(({ pdfPage, viewport }) => {
      // Get the text from the PDF and write it.
      return pdfPage.getTextContent().then((textContent) => {
        return Promise.resolve({
          textContent,
          viewport
        });
      });
    }).
    then(({ textContent, viewport }) => {
      PDFJS.renderTextLayer({
        textContent,
        container: this.textLayer,
        viewport,
        textDivs: []
      });
      this.props.setIfPdfPageIsDrawn(this.props.file, this.props.pageIndex, true);
      this.setIsDrawing(false);

      // If the scale has changed, draw the page again at the latest scale.
      if (currentScale !== this.props.scale) {
        return this.drawPage();
      } else {
        return Promise.resolve();
      }
    }).
    catch(() => {
      this.setIsDrawing(false);
      if (currentScale !== this.props.scale) {
        return this.drawPage();
      } else {
        return Promise.reject();
      }
    });
  }

  componentDidMount = () => {
    this.getDimensions();

    if (this.props.shouldDraw) {
      this.drawPage();
    }
  }

  componentWillUnmount = () => {
    this.props.setIfPdfPageIsDrawn(this.props.file, this.props.pageIndex, false);
    this.setIsDrawing(false);
  }

  componentDidUpdate = (prevProps) => {
    const drawAndUpdateState = () => {
      this.props.setIfPdfPageIsDrawn(this.props.file, this.props.pageIndex, false);
      this.drawPage();
    }
    console.log('inUpdate', this.props.shouldDraw, this.props.scale, prevProps.scale, this.isDrawing);
    if (this.props.shouldDraw) {
      if (!prevProps.shouldDraw) {
        drawAndUpdateState();
      } else if (prevProps.scale !== this.props.scale) {
        drawAndUpdateState();
      }
    }
  }

  getDimensions = () => {
    this.props.pdfDocument.getPage(pageNumberOfPageIndex(this.props.pageIndex)).then((pdfPage) => {
      const PAGE_DIMENSION_SCALE = 1;
      const viewport = pdfPage.getViewport(PAGE_DIMENSION_SCALE);
      const pageDimensions = _.pick(viewport, ['width', 'height']);

      this.props.setPdfPageDimensions(this.props.file, this.props.pageIndex, pageDimensions);
    }).
    catch(() => {
      const pageDimensions = {
        width: PAGE_WIDTH,
        height: PAGE_HEIGHT
      };

      this.props.setPdfPageDimensions(this.props.file, this.props.pageIndex, pageDimensions);
    });
  }

  render() {
    console.log('rendering');

    const pageClassNames = classNames({
      'cf-pdf-pdfjs-container': true,
      page: true,
      'cf-pdf-placing-comment': this.props.isPlacingAnnotation
    });
    const currentWidth = _.get(this.props.pageDimensions, ['width'], PAGE_WIDTH);
    const currentHeight = _.get(this.props.pageDimensions, ['height'], PAGE_HEIGHT);
    const divPageStyle = {
      marginBottom: `${PAGE_MARGIN_BOTTOM * this.props.scale}px`,
      width: `${this.props.scale * currentWidth}px`,
      height: `${this.props.scale * currentHeight}px`,
      verticalAlign: 'top',
      display: this.props.isVisible ? '' : 'none'
    };
    const textLayerStyle = {
      width: `${this.props.scale * currentWidth}px`,
      height: `${this.props.scale * currentHeight}px`
    }
    // Pages that are currently drawing should not be visible since they may be currently rendered
    // at the wrong scale.
    const pageContentsVisibleClass = classNames({
      'cf-pdf-page-hidden': this.props.isDrawing
    });

    return <div
      id={`pageContainer${pageNumberOfPageIndex(this.props.pageIndex)}`}
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
            style={textLayerStyle}
            className="textLayer"/>
        </div>
      </div>;
  }
}

PdfPage.propTypes = {
  documentId: PropTypes.number,
  file: PropTypes.string,
  pageIndex: PropTypes.number,
  isVisible: PropTypes.bool,
  scale: PropTypes.number,
  isDrawn: PropTypes.object,
  getPageContainerRef: PropTypes.func,
  pdfDocument: PropTypes.object
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setPdfPageDimensions,
    setIfPdfPageIsDrawn,
    setIfPdfPageIsDrawing
  }, dispatch)
});

const mapStateToProps = (state, props) => {
  const page = _.get(state.readerReducer, ['documentsByFile', props.file, 'pages', props.pageIndex], {});

  return {
    pageDimensions: _.pick(page, ['width', 'height']),
    isDrawn: page.isDrawn,
    isDrawing: page.isDrawing,
    isPlacingAnnotation: state.readerReducer.ui.pdf.isPlacingAnnotation
  }
};

export default connect(mapStateToProps, mapDispatchToProps)(PdfPage);
