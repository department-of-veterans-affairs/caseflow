import React from 'react';
import PropTypes from 'prop-types';

import CommentLayer from './CommentLayer';
import { connect } from 'react-redux';
import _ from 'lodash';
import { setUpPdfPage, clearPdfPage } from '../reader/actions';
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

// This is the maximum squared distance within which pages are drawn.
// We compare this value with the result of (window_center_x - page_center_x) ^ 2 +
// (window_center_y - page_center_y) ^ 2 which is the square of the distance between
// thef center of the window, and the page. If this is less than MAX_SQUARED_DISTANCE
// then we draw the page. A good value for MAX_SQUARED_DISTANCE is determined empirically
// balancing rendering enough pages in the future with not rendering too many pages in parallel.
const MAX_SQUARED_DISTANCE = 100000000;
const NUMBER_OF_NON_VISIBLE_PAGES_TO_RENDER = 4;

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
  drawPage = () => {
    if (this.isDrawing) {
      return Promise.resolve();
    }
    this.isDrawing = true;

    const currentScale = this.props.scale;
    const viewport = this.props.page.getViewport(this.props.scale);

    // We need to set the width and heights of everything based on
    // the width and height of the viewport.
    this.canvas.height = viewport.height;
    this.canvas.width = viewport.width;

    // Call PDFJS to actually draw the page.
    return this.props.page.render({
      canvasContext: this.canvas.getContext('2d', { alpha: false }),
      viewport
    }).then(() => {
      this.isDrawing = false;
      this.isDrawn = true;
      this.didFailDrawing = false;

      // If the scale has changed, draw the page again at the latest scale.
      if (currentScale !== this.props.scale && this.props.page) {
        return this.drawPage();
      }
    }).
    catch(() => {
      this.didFailDrawing = true;
      this.isDrawing = false;
      this.isDrawn = false;
    });
  }

  clearPage = () => {
    if (this.isDrawn) {
      this.canvas.getContext('2d', { alpha: false }).clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.props.page.cleanup();
    }

    this.isDrawn = false;
  }

  componentDidMount = () => {
    // We only want to setUpPage immediately if it's either on a visible page, or if that page
    // is in a non-visible page but within the first NUMBER_OF_NON_VISIBLE_PAGES_TO_RENDER pages.
    // These are the pages we are most likely to show to the user. All other pages can wait
    // until we have idle time.
    if (this.props.isVisible || this.props.pageIndex < NUMBER_OF_NON_VISIBLE_PAGES_TO_RENDER) {
      this.setUpPage();
    } else {
      window.requestIdleCallback(this.setUpPage);
    }
  }

  clearPdfPage = () => {
    this.props.clearPdfPage(this.props.file, this.props.pageIndex, this.props.page);
  }

  componentWillUnmount = () => {
    this.isDrawing = false;
    this.isDrawn = false;
    this.isUnmounting = true;
    if (this.props.page) {
      this.props.page.cleanup();
    }
    // Cleaning up this page from the Redux store should happen when we have idle time.
    // We don't want to block showing pages because we're too busy cleaning old pages.
    window.requestIdleCallback(this.clearPdfPage);
  }

  // This function gets the square of the distance to the center of the scroll window.
  // We don't calculate linear distance since taking square roots is expensive.
  getSquaredDistanceToCenter = (props) => {
    if (!this.pageContainer) {
      return Number.MAX_SAFE_INTEGER;
    }

    const square = (num) => num * num;
    const boundingRect = this.pageContainer.getBoundingClientRect();
    const pageCenter = {
      x: (boundingRect.left + boundingRect.right) / 2,
      y: (boundingRect.top + boundingRect.bottom) / 2
    };

    return (square(pageCenter.x - props.scrollWindowCenter.x) +
      square(pageCenter.y - props.scrollWindowCenter.y));
  }

  // This function determines whether or not it should draw the page based on its distance
  // from the center of the scroll window, or if it's not visible, then if it's page index
  // is less than NUMBER_OF_NON_VISIBLE_PAGES_TO_RENDER
  shouldDrawPage = (props) => {
    if (!props.isVisible) {
      if (props.pageIndex < NUMBER_OF_NON_VISIBLE_PAGES_TO_RENDER) {
        return true;
      }

      return false;
    }

    return this.getSquaredDistanceToCenter(props) < MAX_SQUARED_DISTANCE;
  }

  componentDidUpdate = (prevProps) => {
    const shouldDraw = this.shouldDrawPage(this.props);

    // We draw the page if there's been a change in the 'shouldDraw' state, scale, or if
    // the page was just loaded.
    if (shouldDraw) {
      // If we have yet to set up the page since we haven't received an idle moment, we force
      // it to be setup here.
      this.setUpPage();

      if (this.props.page && !this.props.page.transport.destroyed && (this.didFailDrawing || !this.previousShouldDraw ||
          prevProps.scale !== this.props.scale || !prevProps.page ||
          (this.props.isVisible && !prevProps.isVisible))) {
        this.drawPage();
      }
    } else if (this.previousShouldDraw) {
      this.clearPage();
    }
    this.previousShouldDraw = shouldDraw;
  }

  drawText = (page, text) => {
    const viewport = page.getViewport(this.props.scale);

    this.textLayer.innerHTML = '';

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
    if (this.isPageSetup) {
      return;
    }

    if (this.props.pdfDocument && !this.props.pdfDocument.transport.destroyed) {
      // We mark the page as setup here. If we error on the promise, then we mark the page
      // as not setup. On every componentDidUpdate we call setUpPage again. This way if
      // we failed to setup the page here, we'll make our best attempt to update it in the future.
      this.isPageSetup = true;
      this.props.pdfDocument.getPage(pageNumberOfPageIndex(this.props.pageIndex)).then((page) => {
        const setUpPageWithText = (text) => {
          const pageData = {
            dimensions: this.props.pageDimensions || this.getDimensions(page),
            page,
            container: this.pageContainer
          };

          if (!this.isUnmounting) {
            this.props.setUpPdfPage(
              this.props.file,
              this.props.pageIndex,
              { ...pageData,
                text }
            );

            this.drawText(page, text);
          }
        };

        // We don't want to get the text again if we already have it saved. So we either
        // use our previous text value, or get the text and then pass it in.
        if (this.props.text) {
          setUpPageWithText(this.props.text);
        } else {
          this.getText(page).then((text) => {
            setUpPageWithText(text);
          });
        }
      }).
      catch(() => {
        this.isPageSetup = false;
      });
    }
  }

  getDimensions = (page) => {
    const PAGE_DIMENSION_SCALE = 1;
    const viewport = page.getViewport(PAGE_DIMENSION_SCALE);

    return _.pick(viewport, ['width', 'height']);
  }

  render() {
    const pageClassNames = classNames({
      'cf-pdf-pdfjs-container': true,
      page: true,
      'cf-pdf-placing-comment': this.props.isPlacingAnnotation
    });
    const width = _.get(this.props.pageDimensions, ['width'], PAGE_WIDTH);
    const height = _.get(this.props.pageDimensions, ['height'], PAGE_HEIGHT);
    const currentWidth = this.props.scale * width;
    const currentHeight = this.props.scale * height;
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
              dimensions={{ width,
                height }}
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
  pdfDocument: PropTypes.object
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearPdfPage,
    setUpPdfPage
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
