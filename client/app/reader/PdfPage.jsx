import React from 'react';
import PropTypes from 'prop-types';
import Mark from 'mark.js';

import CommentLayer from './CommentLayer';
import { connect } from 'react-redux';
import _ from 'lodash';
import { setPageDimensions } from '../reader/Pdf/PdfActions';
import { setDocScrollPosition } from './PdfViewer/PdfViewerActions';
import { text as searchText, getCurrentMatchIndex, getMatchesPerPageInFile } from '../reader/selectors';
import { bindActionCreators } from 'redux';
import { PDF_PAGE_HEIGHT, PDF_PAGE_WIDTH, SEARCH_BAR_HEIGHT } from './constants';
import { pageNumberOfPageIndex } from './utils';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer';

import classNames from 'classnames';

// This comes from the class .pdfViewer.singlePageView .page in _reviewer.scss.
// We need it defined here to be able to expand/contract margin between pages
// as we zoom.
const PAGE_MARGIN_BOTTOM = 25;

// Base scale used to calculate dimensions and draw text.
const PAGE_DIMENSION_SCALE = 1;

export class PdfPage extends React.PureComponent {
  constructor(props) {
    super(props);

    this.isDrawing = false;
    this.marks = [];
  }

  getPageContainerRef = (pageContainer) => this.pageContainer = pageContainer

  getCanvasRef = (canvas) => this.canvas = canvas

  getTextLayerRef = (textLayer) => this.textLayer = textLayer

  unmarkText = (callback = _.noop) => this.markInstance.unmark({ done: callback });
  markText = (scrollToMark = false, txt = this.props.searchText) => {
    this.unmarkText(() => this.markInstance.mark(txt, {
      separateWordSearch: false,
      done: () => {
        if (!this.props.matchesPerPage.length || !this.textLayer) {
          return;
        }

        this.marks = this.textLayer.getElementsByTagName('mark');
        this.highlightMarkAtIndex(scrollToMark);
      }
    }));
  };

  highlightMarkAtIndex = (scrollToMark) => {
    _.each(this.marks, (mark) => mark.classList.remove('highlighted'));

    const [pageIndexWithMatch, indexInPage] = this.getIndexInPage();
    const selectedMark = this.marks[indexInPage];

    if (pageIndexWithMatch === this.props.pageIndex) {
      if (selectedMark) {
        selectedMark.classList.add('highlighted');

        if (scrollToMark) {
          // mark parent elements are absolutely-positioned divs. account for search bar height
          this.props.setDocScrollPosition(
            parseInt(selectedMark.parentElement.style.top, 10) - (SEARCH_BAR_HEIGHT + 10)
          );
        }
      } else {
        console.error('selectedMark not found in DOM');
      }
    }
  }

  getIndexInPage = (matchIndex = this.props.currentMatchIndex) => {
    // get page, relative index of match at absolute index
    let cumulativeMatches = 0;

    for (let matchesPerPageIndex = 0; matchesPerPageIndex < this.props.matchesPerPage.length; matchesPerPageIndex++) {
      if (matchIndex < cumulativeMatches + this.props.matchesPerPage[matchesPerPageIndex].matches) {
        return [
          this.props.matchesPerPage[matchesPerPageIndex].pageIndex,
          this.props.currentMatchIndex - cumulativeMatches
        ];
      }

      cumulativeMatches += this.props.matchesPerPage[matchesPerPageIndex].matches;
    }

    return [-1, -1];
  }

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

      // If the scale has changed, draw the page again at the latest scale.
      if (currentScale !== this.props.scale && page) {
        return this.drawPage(page);
      }
    }).
      catch(() => {
        // We might need to do something else here.
        this.isDrawing = false;
      });
  }

  componentDidMount = () => {
    this.setUpPage();
  }

  componentWillUnmount = () => {
    this.isDrawing = false;
    if (this.props.page) {
      this.props.page.cleanup();
      if (this.markInstance) {
        this.markInstance.unmark();
      }
    }
  }

  componentDidUpdate = (prevProps) => {
    if (prevProps.scale !== this.props.scale) {
      this.drawPage(this.page);
    }

    if (this.markInstance) {
      if (this.props.searchText && !this.props.searchBarHidden) {
        if (!_.isNaN(this.props.currentMatchIndex) && this.props.matchesPerPage && this.marks.length &&
           (this.props.searchText === prevProps.searchText) &&
           (this.props.currentMatchIndex !== prevProps.currentMatchIndex)) {
          // eslint-disable-next-line no-unused-vars
          const [matchedPageIndex, indexInPage] = this.getIndexInPage();

          if (this.marks[indexInPage]) {
            this.highlightMarkAtIndex(true);
          }
        } else {
          this.markText(this.props.currentMatchIndex !== prevProps.currentMatchIndex);
        }
      } else {
        this.unmarkText();
      }
    }
  }

  drawText = (page, text) => {
    if (!this.textLayer) {
      return;
    }

    const viewport = page.getViewport(PAGE_DIMENSION_SCALE);

    this.textLayer.innerHTML = '';

    PDFJS.renderTextLayer({
      textContent: text,
      container: this.textLayer,
      viewport,
      textDivs: []
    });

    this.markInstance = new Mark(this.textLayer);
    if (this.props.searchText && !this.props.searchBarHidden) {
      this.markText(true);
    }
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
          // We might need to do something else here.
        });
    }
  }

  getDimensions = (page) => {
    const viewport = page.getViewport(PAGE_DIMENSION_SCALE);

    this.props.setPageDimensions(
      this.props.file,
      this.props.pageIndex,
      { width: viewport.width,
        height: viewport.height });
  }

  getDivDimensions = () => {
    const innerDivDimensions = {
      innerDivWidth: _.get(this.props.pageDimensions, ['width'], PDF_PAGE_WIDTH),
      innerDivHeight: _.get(this.props.pageDimensions, ['height'], PDF_PAGE_HEIGHT)
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
    setPageDimensions,
    setDocScrollPosition
  }, dispatch)
});

const mapStateToProps = (state, props) => {
  return {
    pageDimensions: _.get(state.readerReducer.pageDimensions, [`${props.file}-${props.pageIndex}`]),
    isPlacingAnnotation: state.readerReducer.ui.pdf.isPlacingAnnotation,
    rotation: _.get(state.readerReducer.documents, [props.documentId, 'rotation'], 0),
    searchText: searchText(state, props),
    currentMatchIndex: getCurrentMatchIndex(state, props),
    matchesPerPage: getMatchesPerPageInFile(state, props),
    searchBarHidden: state.readerReducer.ui.pdf.hideSearchBar
  };
};

export default connect(mapStateToProps, mapDispatchToProps)(PdfPage);
