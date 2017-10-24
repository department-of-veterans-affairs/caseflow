import React from 'react';
import PropTypes from 'prop-types';

import CommentLayer from './CommentLayer';
import { connect } from 'react-redux';
import _ from 'lodash';
import { setPageDimensions } from '../reader/actions';
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

// Base scale used to calculate dimensions and draw text.
const PAGE_DIMENSION_SCALE = 1;

export class PdfPage extends React.PureComponent {
  constructor(props) {
    super(props);

    this.isDrawing = false;
    this.isDrawn = false;
    this.didFailDrawing = false;
    this.previousShouldDraw = false;
    this.isUnmounting = false;
    this.isPageSetup = false;
  }

  getPageContainerRef = (pageContainer) => this.pageContainer = pageContainer

  getCanvasRef = (canvas) => this.canvas = canvas

  getTextLayerRef = (textLayer) => this.textLayer = textLayer

  // This method is the interaction between our component and PDFJS.
  // When this method resolves the returned promise it means the PDF
  // has been drawn with the most up to date scale passed in as a prop.
  // We may execute multiple draws to ensure this property.
  drawPage = (page) => {
    if (this.isDrawing) {
      return Promise.resolve();
    }
    this.isDrawing = true;

    const currentScale = this.props.scale;
    const viewport = page.getViewport(this.props.scale);

    // We need to set the width and heights of everything based on
    // the width and height of the viewport.
    this.canvas.height = viewport.height;
    this.canvas.width = viewport.width;

    // Call PDFJS to actually draw the page.
    return page.render({
      canvasContext: this.canvas.getContext('2d', { alpha: false }),
      viewport
    }).then(() => {
      this.isDrawing = false;
      this.isDrawn = true;
      this.didFailDrawing = false;

      // If the scale has changed, draw the page again at the latest scale.
      if (currentScale !== this.props.scale && page) {
        return this.drawPage(page);
      }
    }).
      catch(() => {
        this.didFailDrawing = true;
        this.isDrawing = false;
        this.isDrawn = false;
      });
  }

  clearPage = () => {
    return;
    if (this.isDrawn) {
      this.canvas.getContext('2d', { alpha: false }).clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.props.page.cleanup();
    }

    this.isDrawn = false;
  }

  componentDidMount = () => {
    console.log('Mounting', this.props.pageIndex);
    this.setUpPage();

    // We only want to setUpPage immediately if it's either on a visible page, or if that page
    // is in a non-visible page but within the first NUMBER_OF_NON_VISIBLE_PAGES_TO_RENDER pages.
    // These are the pages we are most likely to show to the user. All other pages can wait
    // until we have idle time.
    // if (this.props.isVisible || this.props.pageIndex < NUMBER_OF_NON_VISIBLE_PAGES_TO_RENDER) {
    //   this.setUpPage();
    // } else {
    //   window.requestIdleCallback(this.setUpPage);
    // }
  }

  componentWillUnmount = () => {
    console.log('UnMounting', this.props.pageIndex);
    this.isDrawing = false;
    this.isDrawn = false;
    this.isUnmounting = true;
    if (this.page) {
      this.page.cleanup();
    }
  }

  drawText = (page, text) => {
    const viewport = page.getViewport(PAGE_DIMENSION_SCALE);

    this.textLayer.innerHTML = '';
    console.log('drawing text');
    PDFJS.renderTextLayer({
      textContent: text,
      container: this.textLayer,
      viewport,
      textDivs: []
    });
  }

  getText = (page) => page.getTextContent()

  // Set up the page component in the Redux store. This includes the page dimensions, text,
  // and PDFJS page object.
  setUpPage = () => {
    if (this.props.pdfDocument && !this.props.pdfDocument.transport.destroyed) {
      this.props.pdfDocument.getPage(pageNumberOfPageIndex(this.props.pageIndex)).then((page) => {
        this.page = page;

        this.getText(page).then((text) => {
          this.drawText(page, text);
        });

        this.drawPage(page);
        this.getDimensions(page);
      }).
      catch(() => {
        this.isPageSetup = false;
      });
    } else {
      console.log('not setup');
    }
  }

  getDimensions = (page) => {
    const viewport = page.getViewport(PAGE_DIMENSION_SCALE);

    this.props.setPageDimensions(
      this.props.file,
      this.props.pageIndex,
      { width: viewport.width, height: viewport.height });
  }

  getDivDimensions = () => {
    const innerDivDimensions = {
      innerDivWidth: _.get(this.props.pageDimensions, ['width'], PAGE_WIDTH),
      innerDivHeight: _.get(this.props.pageDimensions, ['height'], PAGE_HEIGHT)
    };

    // If we have rotated the page, we need to switch the width and height.
    if (this.props.rotation === 90 || this.props.rotation === 270) {
      return {
        outerDivWidth: this.props.scale * innerDivDimensions.innerDivHeight,
        outerDivHeight: this.props.scale * innerDivDimensions.innerDivWidth,
        ...innerDivDimensions
      };
    }

    return {
      outerDivWidth: this.props.scale * innerDivDimensions.innerDivWidth,
      outerDivHeight: this.props.scale * innerDivDimensions.innerDivHeight,
      ...innerDivDimensions
    };
  }

  render() {
    const pageClassNames = classNames({
      'cf-pdf-pdfjs-container': true,
      page: true,
      'cf-pdf-placing-comment': this.props.isPlacingAnnotation
    });
    const { outerDivWidth, outerDivHeight, innerDivWidth, innerDivHeight } = this.getDivDimensions();

    // When you rotate a page 270 degrees there is a margin on the right equal to the difference
    // between the current width and current height. We need to undo that margin to get things to align.
    const marginTop = this.props.rotation === 270 ? outerDivHeight - outerDivWidth : 0;
    const divPageStyle = {
      marginBottom: `${PAGE_MARGIN_BOTTOM * this.props.scale}px`,
      width: `${outerDivWidth}px`,
      height: `${outerDivHeight}px`,
      verticalAlign: 'top',
      display: this.props.isVisible ? '' : 'none'
    };
    // Pages that are currently drawing should not be visible since they may be currently rendered
    // at the wrong scale.
    const pageContentsVisibleClass = classNames({
      'cf-pdf-page-hidden': this.props.isDrawing
    });
    // This div is the one responsible for rotating the page. It is within the outer div which changes
    // its width and height based on whether this page has been rotated to be in a portrait or landscape view.
    const innerDivStyle = {
      transform: `rotate(${this.props.rotation}deg)`,
      marginTop
    };

    return <div
      id={this.props.isVisible ? `pageContainer${pageNumberOfPageIndex(this.props.pageIndex)}` : null}
      className={pageClassNames}
      style={divPageStyle}
      ref={this.getPageContainerRef}>
      <div
        id={this.props.isVisible ? `rotationDiv${pageNumberOfPageIndex(this.props.pageIndex)}` : null}
        className={pageContentsVisibleClass}
        style={innerDivStyle}>
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
            dimensions={{
              width: innerDivWidth,
              height: innerDivHeight
            }}
            isVisible={this.props.isVisible}
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
  rotate: PropTypes.number,
  pdfDocument: PropTypes.object
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setPageDimensions
  }, dispatch)
});

const mapStateToProps = (state, props) => {
  return {
    pageDimensions: _.get(state.readerReducer.pageDimensions, [`${props.file}-${props.pageIndex}`]),
    isPlacingAnnotation: state.readerReducer.ui.pdf.isPlacingAnnotation,
    rotation: _.get(state.readerReducer.documents, [props.documentId, 'rotation'], 0)
  };
};

export default connect(mapStateToProps, mapDispatchToProps)(PdfPage);
