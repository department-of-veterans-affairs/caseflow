import React from 'react';
import PropTypes from 'prop-types';
import Mark from 'mark.js';
import uuid, { v4 as uuidv4 } from 'uuid';
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
import { recordMetrics, recordAsyncMetrics, storeMetrics } from '../util/Metrics';
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
    this.measureTimeStartMs = props.measureTimeStartMs; // Track the start time for page rendering
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
    return this.renderTask.promise
      .then(() => {
        this.isDrawing = false;
        // If the scale has changed, draw the page again at the latest scale.
        if (currentScale !== this.props.scale && page) {
          return this.drawPage(page);
        }
      })
      .catch((error) => {
        console.error(`${uuid.v4()} : render ${this.props.file} : ${error}`);
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
    if (!this.measureTimeStartMs && this.props.isPageVisible && !prevProps.isPageVisible) {
      this.measureTimeStartMs = performance.now(); // Start measuring time when page becomes visible
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

  setUpPage = () => {
    if (this.props.pdfDocument && !this.props.pdfDocument._transport.destroyed) {
      const pageMetricData = {
        message: 'Storing PDF page',
        product: 'reader',
        type: 'performance',
        data: {
          file: this.props.file,
          documentId: this.props.documentId,
          pageIndex: this.props.pageIndex,
          numPagesInDoc: this.props.pdfDocument.numPages,
          prefetchDisabled: this.props.featureToggles.prefetchDisabled
        },
      };
      const pageAndTextFeatureToggle = this.props.featureToggles.metricsPdfStorePages;
      const document = this.props.pdfDocument;
      const pageIndex = pageNumberOfPageIndex(this.props.pageIndex);
      const pageResult = recordAsyncMetrics(document.getPage(pageIndex), pageMetricData, pageAndTextFeatureToggle);
      pageResult.then((page) => {
        this.page = page;
        const textMetricData = {
          message: 'Storing PDF page text',
          product: 'reader',
          type: 'performance',
          data: {
            file: this.props.file,
            documentId: this.props.documentId,
            pageIndex: this.props.pageIndex,
            numPagesInDoc: this.props.pdfDocument.numPages,
            prefetchDisabled: this.props.featureToggles.prefetchDisabled
          },
        };
        const readerRenderText = {
          uuid: uuidv4(),
          message: 'PDFJS rendering text layer',
          type: 'performance',
          product: 'reader',
          data: {
            documentId: this.props.documentId,
            documentType: this.props.documentType,
            file: this.props.file,
            pageIndex: this.props.pageIndex,
            numPagesInDoc: this.props.pdfDocument.numPages,
            prefetchDisabled: this.props.featureToggles.prefetchDisabled
          },
        };
        const textResult = recordAsyncMetrics(this.getText(page), textMetricData, pageAndTextFeatureToggle);
        textResult.then((text) => {
          recordMetrics(this.drawText(page, text), readerRenderText,
            this.props.featureToggles.metricsReaderRenderText);
        });
        this.drawPage(page).then(() => {
          const data = {
            overscan: this.props.windowingOverscan,
            documentType: this.props.documentType,
            pageCount: this.props.pdfDocument.numPages,
            pageIndex: this.props.pageIndex,
            prefetchDisabled: this.props.featureToggles.prefetchDisabled,
            start: this.measureTimeStartMs,
            end: performance.now()
          };

          // Waits for all the pages before storing metric
          if (this.props.featureToggles.pdfPageRenderTimeInMs && this.props.pageIndex ===
