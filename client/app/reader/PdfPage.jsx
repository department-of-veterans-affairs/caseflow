import React from 'react';
import PropTypes from 'prop-types';
import Mark from 'mark.js';
import { v4 as uuidv4 } from 'uuid';

import CommentLayer from './CommentLayer';
import { connect } from 'react-redux';
import { get, noop, sum, filter, map } from 'lodash';
import { setSearchIndexToHighlight } from './PdfSearch/PdfSearchActions';
import { setDocScrollPosition } from './PdfViewer/PdfViewerActions';
import { getSearchTerm, getCurrentMatchIndex, getMatchesPerPageInFile } from '../reader/selectors';
import { bindActionCreators } from 'redux';
import { PDF_PAGE_HEIGHT, PDF_PAGE_WIDTH, SEARCH_BAR_HEIGHT, PAGE_DIMENSION_SCALE, PAGE_MARGIN } from './constants';
import { pageNumberOfPageIndex } from './utils';
import * as PDFJS from 'pdfjs-dist';
import { collectHistogram, recordMetrics } from '../util/Metrics';

import { css } from 'glamor';
import classNames from 'classnames';
import { COLORS } from '../constants/AppConstants';

const markStyle = css({
  '& mark': {
    background: COLORS.GOLD_LIGHTER,
    '.highlighted': {
      background: COLORS.GREEN_LIGHTER
    }
  }
});

export class PdfPage extends React.PureComponent {
  constructor(props) {
    super(props);

    this.isDrawing = false;
    this.renderTask = null;
    this.marks = [];
    this.measureTimeStartMs = null;
  }

  getPageContainerRef = (pageContainer) => (this.pageContainer = pageContainer);

  getCanvasRef = (canvas) => (this.canvas = canvas);

  getTextLayerRef = (textLayer) => (this.textLayer = textLayer);

  unmarkText = (callback = noop) => this.markInstance.unmark({ done: callback });
  markText = (scrollToMark = false, txt = this.props.searchText) => {
    this.unmarkText(() =>
      this.markInstance.mark(txt, {
        separateWordSearch: false,
        done: () => {
          if (!this.props.matchesPerPage.length || !this.textLayer) {
            return;
          }

          this.marks = this.textLayer.getElementsByTagName('mark');
          this.highlightMarkAtIndex(scrollToMark);
        }
      })
    );
  };

  highlightMarkAtIndex = (scrollToMark) => {
    if (this.props.pageIndexWithMatch !== this.props.pageIndex) {
      return;
    }

    const selectedMark = this.marks[this.props.relativeIndex];

    if (selectedMark) {
      selectedMark.classList.add('highlighted');

      if (scrollToMark) {
        // Mark parent elements are absolutely-positioned divs. Account for search bar and margin height.
        this.props.setDocScrollPosition(
          parseInt(selectedMark.parentElement.style.top, 10) - (SEARCH_BAR_HEIGHT + 10) - PAGE_MARGIN
        );
      }
    } else {
      console.error(
        'selectedMark not found in DOM: ' +
          `${this.props.relativeIndex} on pg ${this.props.pageIndex} (${this.props.currentMatchIndex})`
      );
    }
  };

  getMatchIndexOffsetFromPage = (pageIndex = this.props.pageIndex) => {
    // get sum of matches from pages below pageIndex
    return sum(map(filter(this.props.matchesPerPage, (page) => page.pageIndex < pageIndex), (page) => page.matches));
  };

  onClick = () => {
    if (this.marks.length) {
      this.props.setSearchIndexToHighlight(this.getMatchIndexOffsetFromPage());
    }
  };

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
    const viewport = page.getViewport({ scale: this.props.scale });

    // We need to set the width and heights of everything based on
    // the width and height of the viewport.
    this.canvas.height = viewport.height;
    this.canvas.width = viewport.width;

    const options = {
      canvasContext: this.canvas.getContext('2d', { alpha: false }),
      viewport
    };

    this.renderTask = page.render(options);

    // Call PDFJS to actually draw the page.
    return this.renderTask.promise.then(() => {
      this.isDrawing = false;

      // If the scale has changed, draw the page again at the latest scale.
      if (currentScale !== this.props.scale && page) {
        return this.drawPage(page);
      }
    }).
      catch(() => {
        // We might need to do something else here.
        this.isDrawing = false;
      });
  };

  componentDidMount = () => {
    this.setUpPage();
  };

  componentWillUnmount = () => {
    this.isDrawing = false;

    if (this.renderTask) {
      this.renderTask.cancel();
    }

    if (this.props.page) {
      this.props.page.cleanup();
      if (this.markInstance) {
        this.markInstance.unmark();
      }
    }
  };

  componentDidUpdate = (prevProps) => {
    if (this.props.isPageVisible && !prevProps.isPageVisible) {
      this.measureTimeStartMs = performance.now();
    }

    if (prevProps.scale !== this.props.scale && this.page) {
      this.drawPage(this.page);
    }

    if (this.markInstance) {
      if (this.props.searchBarHidden || !this.props.searchText) {
        this.unmarkText();
      } else {
        const searchTextChanged = this.props.searchText !== prevProps.searchText;
        const currentMatchIdxChanged =
          !isNaN(this.props.relativeIndex) && this.props.relativeIndex !== prevProps.relativeIndex;
        const pageIndexChanged =
          !isNaN(this.props.pageIndexWithMatch) && this.props.pageIndexWithMatch !== prevProps.pageIndexWithMatch;

        if (this.props.matchesPerPage.length || searchTextChanged) {
          this.markText(currentMatchIdxChanged || searchTextChanged || pageIndexChanged);
        }
      }
    }
  };

  drawText = (page, text) => {

    if (!this.textLayer) {
      return;
    }

    const viewport = page.getViewport({ scale: PAGE_DIMENSION_SCALE });

    this.textLayer.innerHTML = '';

    PDFJS.renderTextLayer({
      textContent: text,
      container: this.textLayer,
      viewport,
      textDivs: []
    }).promise.then(() => {
      this.markInstance = new Mark(this.textLayer);

      if (this.props.searchText && !this.props.searchBarHidden) {
        this.markText();
      }
    });
  };

  getText = (page) => page.getTextContent();

  // Set up the page component in the Redux store. This includes the page dimensions, text,
  // and PDFJS page object.
  setUpPage = () => {
    // eslint-disable-next-line no-underscore-dangle
    if (this.props.pdfDocument && !this.props.pdfDocument._transport.destroyed) {
      this.props.pdfDocument.
        getPage(pageNumberOfPageIndex(this.props.pageIndex)).
        then((page) => {
          this.page = page;

          const uuid = uuidv4();

          const readerRenderText = {
            uuid,
            message: 'Searching within Reader document text',
            type: 'performance',
            product: 'reader',
            data: {
              documentId: this.props.documentId,
              documentType: this.props.documentType,
              file: PropTypes.string
            },
          };

          this.getText(page).then((text) => {
            this.drawText(page, text);
            // eslint-disable-next-line max-len
            recordMetrics(this.drawText(page, text), readerRenderText, this.props.featureToggles.metricsReaderRenderText);
          });

          this.drawPage(page).then(() => {
            collectHistogram({
              group: 'front_end',
              name: 'pdf_page_render_time_in_ms',
              value: this.measureTimeStartMs ? performance.now() - this.measureTimeStartMs : 0,
              appName: 'Reader',
              attrs: {
                overscan: this.props.windowingOverscan,
                documentType: this.props.documentType,
                pageCount: this.props.pdfDocument.pdfInfo?.numPages
              }
            });
          });
        }).
        catch(() => {
          // We might need to do something else here.
        });
    }
  };

  getDivDimensions = () => {
    const innerDivDimensions = {
      innerDivWidth: get(this.props.pageDimensions, ['width'], PDF_PAGE_WIDTH),
      innerDivHeight: get(this.props.pageDimensions, ['height'], PDF_PAGE_HEIGHT)
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
  };

  render() {
    const pageClassNames = classNames({
      'cf-pdf-pdfjs-container': true,
      page: true,
      'cf-pdf-placing-comment': this.props.isPlacingAnnotation
    });
    const { outerDivWidth, outerDivHeight, innerDivWidth, innerDivHeight } = this.getDivDimensions();

    // When you rotate a page 90 or 270 degrees there is a translation at the top equal to the difference
    // between the current width and current height. We need to undo that translation to get things to align.
    const translateX = (Math.sin((this.props.rotation / 180) * Math.PI) * (outerDivHeight - outerDivWidth)) / 2;
    const divPageStyle = {
      marginBottom: `${PAGE_MARGIN * this.props.scale}px`,
      width: `${outerDivWidth}px`,
      height: `${outerDivHeight}px`,
      verticalAlign: 'top',
      display: this.props.isFileVisible ? '' : 'none'
    };
    // Pages that are currently drawing should not be visible since they may be currently rendered
    // at the wrong scale.
    const pageContentsVisibleClass = classNames({
      'cf-pdf-page-hidden': this.props.isDrawing
    });
    // This div is the one responsible for rotating the page. It is within the outer div which changes
    // its width and height based on whether this page has been rotated to be in a portrait or landscape view.
    const innerDivStyle = {
      transform: `rotate(${this.props.rotation}deg) translateX(${translateX}px)`
    };

    return (
      <div
        id={this.props.isFileVisible ? `pageContainer${pageNumberOfPageIndex(this.props.pageIndex)}` : null}
        className={pageClassNames}
        style={divPageStyle}
        onClick={this.onClick}
        ref={this.getPageContainerRef}
        {...markStyle}
      >
        <div
          id={this.props.isFileVisible ? `rotationDiv${pageNumberOfPageIndex(this.props.pageIndex)}` : null}
          className={pageContentsVisibleClass}
          style={innerDivStyle}
        >
          <canvas ref={this.getCanvasRef} className="canvasWrapper" />
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
              isVisible={this.props.isFileVisible}
            />
          </div>
        </div>
      </div>
    );
  }
}

PdfPage.propTypes = {
  currentMatchIndex: PropTypes.any,
  documentId: PropTypes.number,
  documentType: PropTypes.any,
  file: PropTypes.string,
  getTextLayerRef: PropTypes.func,
  handleSelectCommentIcon: PropTypes.func,
  isDrawing: PropTypes.any,
  isFileVisible: PropTypes.bool,
  isPageVisible: PropTypes.any,
  isPlacingAnnotation: PropTypes.any,
  isVisible: PropTypes.bool,
  matchesPerPage: PropTypes.shape({
    length: PropTypes.any
  }),
  page: PropTypes.shape({
    cleanup: PropTypes.func
  }),
  pageDimensions: PropTypes.any,
  pageIndex: PropTypes.number,
  pageIndexWithMatch: PropTypes.any,
  pdfDocument: PropTypes.object,
  placingAnnotationIconPageCoords: PropTypes.object,
  relativeIndex: PropTypes.any,
  rotate: PropTypes.number,
  rotation: PropTypes.number,
  scale: PropTypes.number,
  searchBarHidden: PropTypes.bool,
  searchText: PropTypes.string,
  setDocScrollPosition: PropTypes.func,
  setSearchIndexToHighlight: PropTypes.func,
  windowingOverscan: PropTypes.string,
  featureToggles: PropTypes.object
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators(
    {
      setDocScrollPosition,
      setSearchIndexToHighlight
    },
    dispatch
  )
});

const mapStateToProps = (state, props) => {
  return {
    pageDimensions: get(state.pdf.pageDimensions, [props.file, props.pageIndex]),
    isPlacingAnnotation: state.annotationLayer.isPlacingAnnotation,
    rotation: get(state.documents, [props.documentId, 'rotation'], 0),
    searchText: getSearchTerm(state, props),
    currentMatchIndex: getCurrentMatchIndex(state, props),
    matchesPerPage: getMatchesPerPageInFile(state, props),
    searchBarHidden: state.pdfViewer.hideSearchBar,
    windowingOverscan: state.pdfViewer.windowingOverscan,
    documentType: get(state.documents, [props.documentId, 'type'], 'unknown'),
    ...state.searchActionReducer
  };
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(PdfPage);
