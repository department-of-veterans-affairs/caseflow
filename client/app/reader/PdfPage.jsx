import React from 'react';
import PropTypes from 'prop-types';

import CommentLayer from './CommentLayer';
import { connect } from 'react-redux';
import _ from 'lodash';
import { setPdfPageDimensions, setPdfPage, setPdfPageText } from '../reader/actions';
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

const MAXIMUM_DISTANCE = 10000000;
// const MAXIMUM_DISTANCE = 10000000000000;

export class PdfPage extends React.PureComponent {
  constructor(props) {
    super(props);

    this.isDrawing = false;
    this.isDrawn = false;
    this.distance = 0;
  }

  getUniqueId = () => `pageContainer${pageNumberOfPageIndex(this.props.pageIndex)}`

  getPageContainerRef = (pageContainer) => {
    this.pageContainer = pageContainer;
    this.props.getPageContainerRef(this.props.pageIndex, this.props.file, pageContainer);
  }

  getCanvasRef = (canvas) => this.canvas = canvas

  getTextLayerRef = (textLayer) => this.textLayer = textLayer

  setIsDrawing = (value) => {
    this.isDrawing = value;
  }

  setIsDrawn = (value) => {
    this.isDrawn = value;
  }

  // This method is the interaction between our component and PDFJS.
  // When this method resolves the returned promise it means the PDF
  // has been drawn with the most up to date scale passed in as a prop.
  // We may execute multiple draws to ensure this property.
  drawPage = () => {
    if (this.isDrawing) {
      return Promise.reject();
    }
    this.setIsDrawing(true);

    let t0;
    const currentScale = this.props.scale;
    // The viewport is a PDFJS concept that combines the size of the
    // PDF pages with the scale go get the dimensions of the divs.
    const viewport = this.props.page.getViewport(this.props.scale);

    // We need to set the width and heights of everything based on
    // the width and height of the viewport.
    this.canvas.height = viewport.height;
    this.canvas.width = viewport.width;

    console.log('drawing page');
    // Call PDFJS to actually draw the page.
    return this.props.page.render({
        canvasContext: this.canvas.getContext('2d', { alpha: false }),
        viewport
      }).
      then(() => {
        this.setIsDrawn(true);
        this.setIsDrawing(false);

        // If the scale has changed, draw the page again at the latest scale.
        if (currentScale !== this.props.scale) {
          return this.drawPage();
        }
      }).
      catch(() => {
        this.setIsDrawing(false);
      });
  }

  clearPage = () => {
    if (this.isDrawn) {
      this.canvas.getContext('2d', { alpha: false }).clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.props.page.cleanup();
      // console.log('cleaning up page', this.canvas.width, this.canvas.height);
    }

    this.setIsDrawn(false);
  }

  componentDidMount = () => {
    this.getPage();
  }

  componentWillUnmount = () => {
    this.setIsDrawn(false);
    this.setIsDrawing(false);
    this.props.page.cleanup();
    this.props.setPdfPage(this.props.file, this.props.pageIndex, page);
  }

  getSquaredDistanceToCenter = (props) => {
    if (!this.props.isVisible) {
      if (this.props.pageIndex < 2) {
        return MAXIMUM_DISTANCE - 1;
      } else {
        return MAXIMUM_DISTANCE + 1;
      }
    }

    const boundingRect = this.pageContainer.getBoundingClientRect();
    const pageCenter = {
      x: (boundingRect.left + boundingRect.right) / 2,
      y: (boundingRect.top + boundingRect.bottom) / 2
    };

    return (Math.pow(pageCenter.x - props.scrollWindowCenter.x, 2) + Math.pow(pageCenter.y - props.scrollWindowCenter.y, 2));
  }

  componentDidUpdate = (prevProps) => {
    if (prevProps.text !== this.props.text || prevProps.scale !== this.props.scale) {
      this.drawText();
    }

    const drawAndUpdateState = () => {
      this.drawPage();
    };

    const distance = this.getSquaredDistanceToCenter(this.props);

    if (distance < MAXIMUM_DISTANCE) {
      if (this.props.page) {
        if (this.distance >= MAXIMUM_DISTANCE || prevProps.scale !== this.props.scale || !prevProps.page) {
          drawAndUpdateState();
        }
      }
    } else {
      if (this.distance < MAXIMUM_DISTANCE) {
        this.clearPage();
      }
    }
    this.distance = distance;
  }

  drawText = () => {
    const viewport = this.props.page.getViewport(this.props.scale);

    this.textLayer.innerHTML = '';

    PDFJS.renderTextLayer({
      textContent: this.props.text,
      container: this.textLayer,
      viewport,
      textDivs: []
    });
    this.setIsDrawing(false);
  }

  getText = (page) => {
    // Get the text from the PDF and write it.
    return page.getTextContent().then((textContent) => {
      this.props.setPdfPageText(this.props.file, this.props.pageIndex, textContent);
    });
  }

  getPage = () => {
    this.props.pdfDocument.getPage(pageNumberOfPageIndex(this.props.pageIndex)).then((page) => {
      this.props.setPdfPage(this.props.file, this.props.pageIndex, page);
      console.log('calling update');
      if (!this.props.pageDimensions) {
        this.getDimensions(page);
      }
      if (!this.props.text) {
        this.getText(page);
      }
    });
  }

  getDimensions = (page) => {
    new Promise(() => {
      const PAGE_DIMENSION_SCALE = 1;
      const viewport = page.getViewport(PAGE_DIMENSION_SCALE);
      const pageDimensions = _.pick(viewport, ['width', 'height']);

      this.props.setPdfPageDimensions(this.props.file, this.props.pageIndex, pageDimensions);
    })
  }

  render() {
    const pageClassNames = classNames({
      'cf-pdf-pdfjs-container': true,
      page: true,
      'cf-pdf-placing-comment': this.props.isPlacingAnnotation
    });
    const currentWidth = this.props.scale * _.get(this.props.pageDimensions, ['width'], PAGE_WIDTH);
    const currentHeight = this.props.scale * _.get(this.props.pageDimensions, ['height'], PAGE_HEIGHT);
    const divPageStyle = {
      marginBottom: `${PAGE_MARGIN_BOTTOM * this.props.scale}px`,
      width: `${currentWidth}px`,
      height: `${currentHeight}px`,
      verticalAlign: 'top',
      display: this.props.isVisible ? '' : 'none'
    };
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
            <CommentLayer
              documentId={this.props.documentId}
              pageIndex={this.props.pageIndex}
              scale={this.props.scale}
              getTextLayerRef={this.getTextLayerRef}
              file={this.props.file}
              dimensions={{ currentWidth,
                currentHeight }}
            />
          </div>
        </div>
      </div>;
  }
}

PdfPage.propTypes = {
  scrollWindowCenter: PropTypes.shape({
    x: PropTypes.number,
    y: PropTypes.number
  }),
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
    setPdfPage,
    setPdfPageText
  }, dispatch)
});

const mapStateToProps = (state, props) => {

  const page = state.readerReducer.pages[`${props.file}-${props.pageIndex}`];

  return {
    pageDimensions: _.get(page, ['dimensions']),
    page: _.get(page, ['page']),
    text: _.get(page, ['text']),
    isPlacingAnnotation: state.readerReducer.ui.pdf.isPlacingAnnotation
  };
};

export default connect(mapStateToProps, mapDispatchToProps)(PdfPage);
