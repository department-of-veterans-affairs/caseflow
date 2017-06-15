/* eslint-disable max-lines */

import React from 'react';
import PropTypes from 'prop-types';

import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import { bindActionCreators } from 'redux';
import { keyOfAnnotation, isUserEditingText } from '../reader/utils';

import CommentIcon from './CommentIcon';
import { connect } from 'react-redux';
import _ from 'lodash';
import classNames from 'classnames';
import { handleSelectCommentIcon, setPdfReadyToShow, setPageCoordBounds,
  placeAnnotation, requestMoveAnnotation, startPlacingAnnotation,
  stopPlacingAnnotation, showPlaceAnnotationIcon, hidePlaceAnnotationIcon } from '../reader/actions';
import { makeGetAnnotationsByDocumentId } from '../reader/selectors';

const pageNumberOfPageIndex = (pageIndex) => pageIndex + 1;

// If we used CSS in JS, we wouldn't have to keep this value in sync with the CSS in a brittle way.
const ANNOTATION_ICON_SIDE_LENGTH = 40;

const getScaledCoords = ({ x, y }, scale) => ({
  x: x / scale,
  y: y / scale
});

const pageCoordsOfScreenCoords = ({ x, y }, pageBoundingBox) => ({
  x: x - pageBoundingBox.left,
  y: y - pageBoundingBox.top
});

export const getInitialAnnotationIconScaledPageCoords = (iconPageBoundingBox, scrollWindowBoundingRect, scale) => {
  const leftBound = Math.max(scrollWindowBoundingRect.left, iconPageBoundingBox.left);
  const rightBound = Math.min(scrollWindowBoundingRect.right, iconPageBoundingBox.right);
  const topBound = Math.max(scrollWindowBoundingRect.top, iconPageBoundingBox.top);
  const bottomBound = Math.min(scrollWindowBoundingRect.bottom, iconPageBoundingBox.bottom);

  const screenCoords = {
    x: _.mean([leftBound, rightBound]),
    y: _.mean([topBound, bottomBound])
  };

  const pageCoords = pageCoordsOfScreenCoords(screenCoords, iconPageBoundingBox);
  const scaledCoords = getScaledCoords(pageCoords, scale);

  const annotationIconOffset = ANNOTATION_ICON_SIDE_LENGTH / 2;

  return {
    x: scaledCoords.x - annotationIconOffset,
    y: scaledCoords.y - annotationIconOffset
  };
};

// This comes from the class .pdfViewer.singlePageView .page in _reviewer.scss.
// We need it defined here to be able to expand/contract margin between pages
// as we zoom.
const PAGE_MARGIN_BOTTOM = 25;
const RENDER_WITHIN_SCROLL = 1000;
// This is the default page width.
const PAGE_WIDTH = 1;
// This comes from _pdf_viewer.css and is the default height
// of the pages in the PDF. We need it defined here to be
// able to expand/contract the height of the pages as we zoom.
const PAGE_HEIGHT = 1056;

const COVER_SCROLL_HEIGHT = 120;

const NUM_PAGES_TO_PRERENDER = 2;

// The Pdf component encapsulates PDFJS to enable easy rendering of PDFs.
// The component will speed up rendering by only rendering pages when
// they become visible.
export class Pdf extends React.PureComponent {
  constructor(props) {
    super(props);
    // We use two variables to maintain the state of rendering.
    // isRendering below is outside of the state variable.
    // isRendering[pageNumber] is true when a page is currently
    // being rendered by PDFJS. It is set to false when rendering
    // is either successful or aborts.
    // isRendered is in the state variable, since an update to
    // isRendered should trigger a render update since we need to
    // draw comments after a page is rendered. Once a page is
    // successfully rendered we set isRendered[pageNumber] to be the
    // filename of the rendered PDF. This way, if PDFs are changed
    // we know which pages are stale.
    this.state = {
      numPages: null,
      pdfDocument: null,
      isRendered: []
    };

    this.scrollLocation = {
      page: null,
      locationOnPage: 0
    };

    this.currentPage = 0;
    this.isRendering = [];
    this.prerenderedPdfs = {};
    this.isPrerendering = false;

    this.pageElements = {};
    this.fakeCanvas = [];
    this.scrollWindow = null;

    this.refFunctionGetters = {};
    this.setUpFakeCanvasRefFunctions();
  }

  setIsRendered = (index, value) => {
    this.isRendering[index] = false;
    let isRendered = [...this.state.isRendered];

    isRendered[index] = value;
    this.setState({
      isRendered
    });
  }

  setElementDimensions = (element, dimensions) => {
    element.style.width = `${dimensions.width}px`;
    element.style.height = `${dimensions.height}px`;
  }

  // This method is the worst. It is our main interaction with PDFJS, so it will
  // likey remain complicated.
  renderPage = (index) => {
    if (this.isRendering[index] ||
      (_.get(this.state.isRendered[index], 'pdfDocument') === this.state.pdfDocument &&
      _.get(this.state.isRendered[index], 'scale') === this.props.scale)) {
      return Promise.resolve();
    }

    let pdfDocument = this.state.pdfDocument;
    let { scale } = this.props;

    // Mark that we are rendering this page.
    this.isRendering[index] = true;

    return new Promise((resolve, reject) => {
      if (index >= this.state.numPages || pdfDocument !== this.state.pdfDocument) {
        this.isRendering[index] = false;

        return resolve();
      }

      // Page numbers are one-indexed
      let pageNumber = index + 1;
      let canvas = this.pageElements[index].canvas;
      let container = this.pageElements[index].textLayer;
      let page = this.pageElements[index].pageContainer;

      if (!canvas || !container || !page) {
        this.isRendering[index] = false;

        return reject();
      }

      pdfDocument.getPage(pageNumber).then((pdfPage) => {
        // The viewport is a PDFJS concept that combines the size of the
        // PDF pages with the scale go get the dimensions of the divs.
        let viewport = pdfPage.getViewport(this.props.scale);

        // We need to set the width and heights of everything based on
        // the width and height of the viewport.
        canvas.height = viewport.height;
        canvas.width = viewport.width;

        this.setElementDimensions(container, viewport);
        this.setElementDimensions(page, viewport);
        container.innerHTML = '';

        // Call PDFJS to actually render the page.
        return pdfPage.render({
          canvasContext: canvas.getContext('2d', { alpha: false }),
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
        // Get the text from the PDF and render it.
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
          container,
          viewport,
          textDivs: []
        });

        // After rendering everything, we check to see if
        // the PDF we just rendered is the same as the PDF
        // in the current state. It is possible that the
        // user switched between PDFs quickly and this
        // condition is no longer true, in which case we
        // should render this page again with the new file. We
        // also check if the canvas rendered on still exists.
        // If the pages are changed quickly it's possible to
        // render on a canvas that has since been changed which
        // means we need to render it again.
        if (pdfDocument === this.state.pdfDocument && canvas === this.pageElements[index].canvas) {
          // If it is the same, then we mark this page as rendered
          this.setIsRendered(index, {
            pdfDocument,
            scale,
            ..._.pick(viewport, ['width', 'height'])
          });

          // Whenever we finish rendering a page, we assume that this was the last page
          // to render within the current document. We then try to prerender pages for documents in the
          // prefetchFiles list. The prerenderPages call validates this assumption by
          // checking if any other pages of the current document are being rendered,
          // and will not proceed if they are since we want the current document's pages
          // to take precedence over prerendering other documents' pages.
          this.prerenderPages();

          // this.props.file may not be a value in this.prerenderedPdfs. If it is not
          // already present, then we want to create it.
          _.set(this.prerenderedPdfs, [this.props.file, 'rendered', index], true);
          resolve();
        } else {
          // If it is not, then we try to render it again.
          this.isRendering[index] = false;
          this.renderPage(index).then(() => {
            resolve();
          }).
          catch(() => {
            this.isRendering[index] = false;
            reject();
          });
        }
      }).
      catch(() => {
        this.isRendering[index] = false;
        reject();
      });
    });
  }

  scrollEvent = () => {
    // Now that the user is scrolling we reset the scroll location
    // so that we do not keep scrolling the user back.
    this.scrollLocation = {
      page: null,
      locationOnPage: 0
    };

    this.performFunctionOnEachPage((boundingRect, index) => {
      // You are on this page, if the top of the page is above the middle
      // and the bottom of the page is below the middle
      // jumpToPageNumber check is added to not update the page number when the
      // jump to page scroll is activated.
      if (!this.props.jumpToPageNumber && boundingRect.top < this.scrollWindow.clientHeight / 2 &&
          boundingRect.bottom > this.scrollWindow.clientHeight / 2) {
        this.onPageChange(index + 1);
      }
    });

    if (this.props.jumpToPageNumber) {
      this.props.resetJumpToPage();
    }
    this.renderInViewPages();
  }

  renderInViewPages = () => {
    this.performFunctionOnEachPage((boundingRect, index) => {
      // This renders each page as it comes into view. i.e. when
      // the top of the next page is within a thousand pixels of
      // the current view we render it. If the bottom of the page
      // above is within a thousand pixels of the current view
      // we also render it.
      // TODO: Make this more robust.
      if (boundingRect.bottom > -RENDER_WITHIN_SCROLL &&
          boundingRect.top < this.scrollWindow.clientHeight + RENDER_WITHIN_SCROLL) {
        this.renderPage(index, this.props.file);
      }
    });
  }

  performFunctionOnEachPage = (func) => {
    _.forEach(this.pageElements, (ele, index) => {
      if (ele.pageContainer) {
        const boundingRect = ele.pageContainer.getBoundingClientRect();

        func(boundingRect, Number(index));
      }
    });
  }

  // This method sets up the PDF. It sends a web request for the file
  // and when it receives it, starts to render it.
  setUpPdf = (file) => {
    this.latestFile = file;

    return new Promise((resolve) => {
      this.getDocument(this.latestFile).then((pdfDocument) => {
        // Don't continue seting up the pdf if it's already been set up.
        if (pdfDocument === this.state.pdfDocument) {
          return resolve();
        }

        this.pageElements = {};

        this.refFunctionGetters.canvas = [];
        this.refFunctionGetters.textLayer = [];
        this.refFunctionGetters.pageContainer = [];

        _.range(pdfDocument.pdfInfo.numPages).forEach((index) => {
          const makeSetRef = (elemKey) => (elem) => {
            // We only want to save the element if it actually exists.
            // When the node unmounts, React will call the ref function
            // with null. When this happens, we want to delete the
            // entire pageElements object for this index, instead of
            // setting it as a null value. This makes code that reads
            // this.pageElements much simpler, because it does not need
            // to account for the possibility that some pageElements are
            // nulled out because they refer to pages that are no longer rendered.
            if (elem) {
              _.set(this.pageElements, [index, elemKey], elem);
              if (elemKey === 'pageContainer') {
                elem.addEventListener('mousemove', this.mouseListener);
              }
            } else {
              delete this.pageElements[index];
            }
          };

          this.refFunctionGetters.canvas[index] = makeSetRef('canvas');
          this.refFunctionGetters.textLayer[index] = makeSetRef('textLayer');
          this.refFunctionGetters.pageContainer[index] = makeSetRef('pageContainer');
        });

        this.setState({
          numPages: pdfDocument.pdfInfo.numPages,
          pdfDocument,
          isRendered: []
        }, () => {
          // If the user moves between pages quickly we want to make sure that we just
          // set up the most recent file, so we call this function recursively.
          this.setUpPdf(this.latestFile).then(() => {
            this.onPageChange(1);
            this.props.setPdfReadyToShow(this.props.documentId);
            resolve();
          });
        });
      });
    });
  }

  getDocument = (file) => {
    if (_.get(this.prerenderedPdfs, [file, 'pdfDocument'])) {
      return Promise.resolve(this.prerenderedPdfs[file].pdfDocument);
    }

    return PDFJS.getDocument(file).then((pdfDocument) => {
      // There is a chance another async call has resolved in the time that
      // getDocument took to run. If so, again just use the cached version.
      if (_.get(this.prerenderedPdfs, [file, 'pdfDocument'])) {
        return this.prerenderedPdfs[file].pdfDocument;
      }
      this.prerenderedPdfs[file] = {
        pdfDocument,
        rendered: []
      };

      return pdfDocument;
    });
  }

  onJumpToComment = (comment) => {
    if (comment) {
      const pageNumber = comment.page;
      const yPosition = comment.y;

      this.renderPage(pageNumber - 1).then(() => {
        const boundingBox = this.scrollWindow.getBoundingClientRect();
        const height = (boundingBox.bottom - boundingBox.top);
        const halfHeight = height / 2;

        this.scrollWindow.scrollTop =
          this.pageElements[pageNumber - 1].pageContainer.getBoundingClientRect().top +
          yPosition + this.scrollWindow.scrollTop - halfHeight;
      });
    }
  }

  onPageChange = (currentPage) => {
    const unscaledHeight = (this.pageElements[currentPage - 1].pageContainer.offsetHeight / this.props.scale);

    this.currentPage = currentPage;
    this.props.onPageChange(
      currentPage,
      this.state.numPages,
      this.scrollWindow.offsetHeight / unscaledHeight);
  }

  handleAltC = () => {
    this.props.startPlacingAnnotation();

    const scrollWindowBoundingRect = this.scrollWindow.getBoundingClientRect();
    const firstPageWithRoomForIconIndex = _(this.pageElements).
      map('pageContainer').
      findIndex((pageContainer) =>
        pageContainer.getBoundingClientRect().bottom >= scrollWindowBoundingRect.top + ANNOTATION_ICON_SIDE_LENGTH);

    const iconPageBoundingBox =
      this.pageElements[firstPageWithRoomForIconIndex].pageContainer.getBoundingClientRect();

    const scaledPageCoords = getInitialAnnotationIconScaledPageCoords(
      iconPageBoundingBox,
      scrollWindowBoundingRect,
      this.props.scale
    );

    this.props.showPlaceAnnotationIcon(firstPageWithRoomForIconIndex, scaledPageCoords);
  }

  handleAltEnter = () => {
    this.props.placeAnnotation(
      pageNumberOfPageIndex(this.props.placingAnnotationIconScaledPageCoords.pageIndex),
      {
        xPosition: this.props.placingAnnotationIconScaledPageCoords.x,
        yPosition: this.props.placingAnnotationIconScaledPageCoords.y
      },
      this.props.documentId
    );
  }

  keyListener = (event) => {
    if (isUserEditingText()) {
      return;
    }

    if (event.altKey) {
      if (event.code === 'KeyC') {
        this.handleAltC();
      }

      if (event.code === 'Enter') {
        this.handleAltEnter();
      }
    }

    if (event.code === 'Escape' && this.props.isPlacingAnnotation) {
      this.props.stopPlacingAnnotation();
    }
  }

  mouseListener = (event) => {
    const pageIndex = _(this.pageElements).
      map('pageContainer').
      indexOf(event.currentTarget);
    const { xPosition, yPosition } = this.getPageCoordinatesOfMouseEvent(
      event,
      event.currentTarget.getBoundingClientRect()
    );

    this.props.showPlaceAnnotationIcon(pageIndex, {
      x: xPosition,
      y: yPosition
    });
  }

  componentDidMount() {
    PDFJS.workerSrc = this.props.pdfWorker;
    window.addEventListener('resize', this.renderInViewPages);
    window.addEventListener('keydown', this.keyListener);

    this.setUpPdf(this.props.file);

    // focus the scroll window when the component initially loads.
    this.scrollWindow.focus();
    this.updatePageBounds();
  }

  comopnentWillUnmount() {
    window.removeEventListener('resize', this.renderInViewPages);
    window.removeEventListener('keydown', this.keyListener);
  }

  setUpFakeCanvasRefFunctions = () => {
    this.refFunctionGetters.fakeCanvas = [];

    this.props.prefetchFiles.forEach((_unused, index) => {
      _.range(NUM_PAGES_TO_PRERENDER).forEach((pageIndex) => {
        _.set(
          this.refFunctionGetters,
          ['fakeCanvas', index, pageIndex],
          (ele) => _.set(this.fakeCanvas, [index, pageIndex], ele));
      });
    });
  }

  componentWillReceiveProps(nextProps) {
    // In general I think this is a good lint rule. However,
    // I think the below statements are clearer
    // with negative conditions.
    /* eslint-disable no-negated-condition */
    if (nextProps.file !== this.props.file) {
      this.scrollWindow.scrollTop = 0;
      this.setUpPdf(nextProps.file);

      // focus the scroll window when the document changes.
      this.scrollWindow.focus();
    } else if (nextProps.scale !== this.props.scale) {
      // Set the scroll location based on the current page and where you
      // are on that page scaled by the zoom factor.
      const zoomFactor = nextProps.scale / this.props.scale;
      const nonZoomedLocation = (this.scrollWindow.scrollTop -
        this.pageElements[this.currentPage - 1].pageContainer.offsetTop);

      this.scrollLocation = {
        page: this.currentPage,
        locationOnPage: nonZoomedLocation * zoomFactor
      };
    }

    if (nextProps.prefetchFiles !== this.props.prefetchFiles) {
      this.setUpFakeCanvasRefFunctions();
    }
    /* eslint-enable no-negated-condition */
  }

  prerenderPages = () => {
    const finishPrerender = () => {
      this.isPrerendering = false;
      this.prerenderPages();
    };

    // Don't prerender if we are currently trying to render a page on the current document.
    // We want those pages to take precedence over pages on non-visible documents.
    // At the end of rendering pages from this document we always call prerenderPages
    // again in case there are still pages to prerender.
    if (_.some(this.isRendering)) {
      return;
    }

    this.props.prefetchFiles.forEach((file, index) => {
      this.getDocument(file).then((pdfDocument) => {
        _.range(NUM_PAGES_TO_PRERENDER).forEach((pageIndex) => {
          if (pageIndex < pdfDocument.pdfInfo.numPages &&
            !_.get(this.prerenderedPdfs, [file, 'rendered', pageIndex]) &&
            this.fakeCanvas[index][pageIndex] &&
            !this.isPrerendering) {
            // We set this to true, so that only one page can prerender at a time. In this
            // way we can prerender page 1 before prerendering page 2.
            this.isPrerendering = true;

            pdfDocument.getPage(pageIndex + 1).then((pdfPage) => {
              const viewport = pdfPage.getViewport(this.props.scale);

              return pdfPage.render({
                canvasContext: this.fakeCanvas[index][pageIndex].getContext('2d', { alpha: false }),
                viewport
              });
            }).
            then(() => {
              this.prerenderedPdfs[file].rendered[pageIndex] = true;
              finishPrerender();
            }).
            catch(finishPrerender);
          }
        });
      });
    });
  }

  scrollToPage(pageNumber) {
    this.scrollWindow.scrollTop =
      this.pageElements[pageNumber - 1].pageContainer.getBoundingClientRect().top +
      this.scrollWindow.scrollTop - COVER_SCROLL_HEIGHT;
  }

  componentDidUpdate = () => {
    this.renderInViewPages();
    this.prerenderPages();

    // if jump to page number is provided
    // render the page and jump to the page
    if (this.props.jumpToPageNumber) {
      this.scrollToPage(this.props.jumpToPageNumber);
      this.onPageChange(this.props.jumpToPageNumber);
    }
    if (this.props.scrollToComment) {
      if (this.props.documentId === this.props.scrollToComment.documentId &&
        this.state.pdfDocument && this.props.pdfsReadyToShow[this.props.documentId]) {
        this.onJumpToComment(this.props.scrollToComment);
      }
    }

    if (this.scrollLocation.page) {
      this.scrollWindow.scrollTop = this.scrollLocation.locationOnPage +
        this.pageElements[this.scrollLocation.page - 1].pageContainer.offsetTop;
    }
    this.updatePageBounds();
  }

  updatePageBounds = () => {
    const newPageBounds = _.map(this.pageElements, (pageElem, pageIndex) => {
      const boundingRect = pageElem.pageContainer.getBoundingClientRect();
      const upperBound = {
        x: boundingRect.right, 
        y: boundingRect.bottom
      };
      const upperBoundPageCoords = pageCoordsOfScreenCoords(upperBound, boundingRect);

      // I think we need to scale the coords, too.
      return {
        pageIndex: Number(pageIndex),
        right: upperBoundPageCoords.x,
        bottom: upperBoundPageCoords.y
      };
    });

    this.props.setPageCoordBounds(newPageBounds);
  }

  // Move the comment when it's dropped on a page
  onCommentDrop = (pageNumber) => (event) => {
    event.preventDefault();
    let data = JSON.parse(event.dataTransfer.getData('text'));
    let pageBox = document.getElementById(`pageContainer${pageNumber}`).
      getBoundingClientRect();

    let coordinates = {
      x: (event.pageX - pageBox.left - data.iconCoordinates.x) / this.props.scale,
      y: (event.pageY - pageBox.top - data.iconCoordinates.y) / this.props.scale
    };

    const droppedAnnotation = {
      ...this.props.allAnnotations[data.uuid],
      ...coordinates
    };

    this.props.requestMoveAnnotation(droppedAnnotation);
  }

  onPageDragOver = (event) => {
    // The cursor will display a + icon over droppable components.
    // To specify the component as droppable, we need to preventDefault
    // on the event.
    event.preventDefault();
  }

  getScrollWindowRef = (scrollWindow) => this.scrollWindow = scrollWindow

  getPageCoordinatesOfMouseEvent(event, container) {
    const constrainedScreenCoords = {
      x: _.clamp(event.pageX, container.left, container.right - ANNOTATION_ICON_SIDE_LENGTH),
      y: _.clamp(event.pageY, container.top, container.bottom - ANNOTATION_ICON_SIDE_LENGTH)
    };

    const coords = getScaledCoords(pageCoordsOfScreenCoords(constrainedScreenCoords, container), this.props.scale);

    return {
      xPosition: coords.x,
      yPosition: coords.y
    };
  }

  // eslint-disable-next-line max-statements
  render() {
    const annotations = this.props.placingAnnotationIconScaledPageCoords && this.props.isPlacingAnnotation ?
      this.props.comments.concat([{
        temporaryId: 'placing-annotation-icon',
        page: this.props.placingAnnotationIconScaledPageCoords.pageIndex + 1,
        isPlacingAnnotationIcon: true,
        ..._.pick(this.props.placingAnnotationIconScaledPageCoords, 'x', 'y')
      }]) :
      this.props.comments;

    const commentIcons = annotations.reduce((acc, comment) => {
      // Only show comments on a page if it's been rendered
      if (_.get(this.state.isRendered[comment.page - 1], 'pdfDocument') !==
        this.state.pdfDocument) {
        return acc;
      }
      if (!acc[comment.page]) {
        acc[comment.page] = [];
      }

      acc[comment.page].push(
        <CommentIcon
          comment={comment}
          position={{
            x: comment.x * this.props.scale,
            y: comment.y * this.props.scale
          }}
          key={keyOfAnnotation(comment)}
          onClick={comment.isPlacingAnnotationIcon ? _.noop : this.props.handleSelectCommentIcon} />);

      return acc;
    }, {});

    let pages = [];
    const pageClassNames = classNames({
      'cf-pdf-pdfjs-container': true,
      page: true,
      'cf-pdf-placing-comment': this.props.isPlacingAnnotation
    });

    for (let pageNumber = 1; pageNumber <= this.state.numPages; pageNumber++) {
      const onPageClick = (event) => {
        if (!this.props.isPlacingAnnotation) {
          return;
        }

        const { xPosition, yPosition } = this.getPageCoordinatesOfMouseEvent(
          event,
          this.pageElements[pageNumber - 1].pageContainer.getBoundingClientRect()
        );

        this.props.placeAnnotation(pageNumber, {
          xPosition,
          yPosition
        }, this.props.documentId);
      };

      const relativeScale = this.props.scale / _.get(this.state.isRendered[pageNumber - 1], 'scale', 1);
      const currentWidth = _.get(this.state.isRendered[pageNumber - 1], 'width', PAGE_WIDTH);
      const currentHeight = _.get(this.state.isRendered[pageNumber - 1], 'height', PAGE_HEIGHT);

      // Only pages that are the correct scale should be visible
      const CORRECT_SCALE_DELTA_THRESHOLD = 0.01;
      const pageContentsVisibleClass = classNames({
        'cf-pdf-page-hidden': !(Math.abs(relativeScale - 1) < CORRECT_SCALE_DELTA_THRESHOLD)
      });

      pages.push(<div
        className={pageClassNames}
        style={ {
          marginBottom: `${PAGE_MARGIN_BOTTOM * this.props.scale}px`,
          width: `${relativeScale * currentWidth}px`,
          height: `${relativeScale * currentHeight}px`
        } }
        onDragOver={this.onPageDragOver}
        onDrop={this.onCommentDrop(pageNumber)}
        key={`${this.props.file}-${pageNumber}`}
        onClick={onPageClick}
        id={`pageContainer${pageNumber}`}
        ref={this.refFunctionGetters.pageContainer[pageNumber - 1]}>
          <div className={pageContentsVisibleClass}>
            <canvas
              id={`canvas${pageNumber}-${this.props.file}`}
              ref={this.refFunctionGetters.canvas[pageNumber - 1]}
              className="canvasWrapper" />
            <div className="cf-pdf-annotationLayer">
              {commentIcons[pageNumber]}
            </div>
            <div
              id={`textLayer${pageNumber}`}
              ref={this.refFunctionGetters.textLayer[pageNumber - 1]}
              className="textLayer"/>
          </div>
        </div>);
    }

    const prerenderCanvases = this.props.prefetchFiles.map((_unused, index) => {
      return _.range(NUM_PAGES_TO_PRERENDER).map((pageIndex) =>
        <canvas
          style={{ display: 'none' }}
          key={`${pageIndex}-${index}`}
          ref={_.get(this.refFunctionGetters.fakeCanvas, [index, pageIndex])}/>
      );
    });

    return <div
      id="scrollWindow"
      tabIndex="0"
      className="cf-pdf-scroll-view"
      onScroll={_.debounce(this.scrollEvent, 0)}
      ref={this.getScrollWindowRef}>
      {prerenderCanvases}
        <div
          id={this.props.file}
          className={'cf-pdf-page pdfViewer singlePageView'}>
          {pages}
        </div>
      </div>;
  }
}

const mapStateToProps = (state, ownProps) => ({
  ...state.ui.pdf,
  ..._.pick(state, 'placingAnnotationIconScaledPageCoords'),
  comments: makeGetAnnotationsByDocumentId(state)(ownProps.documentId),
  allAnnotations: state.annotations
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    placeAnnotation,
    setPageCoordBounds,
    startPlacingAnnotation,
    stopPlacingAnnotation,
    showPlaceAnnotationIcon,
    hidePlaceAnnotationIcon,
    requestMoveAnnotation
  }, dispatch),
  setPdfReadyToShow: (docId) => dispatch(setPdfReadyToShow(docId)),
  handleSelectCommentIcon: (comment) => dispatch(handleSelectCommentIcon(comment))
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(Pdf);


Pdf.defaultProps = {
  onPageChange: _.noop,
  prefetchFiles: [],
  scale: 1
};

Pdf.propTypes = {
  selectedAnnotationId: PropTypes.number,
  comments: PropTypes.arrayOf(PropTypes.shape({
    comment: PropTypes.string,
    uuid: PropTypes.number,
    page: PropTypes.number,
    x: PropTypes.number,
    y: PropTypes.number
  })),
  documentId: PropTypes.number.isRequired,
  file: PropTypes.string.isRequired,
  pdfWorker: PropTypes.string.isRequired,
  scale: PropTypes.number,
  onPageChange: PropTypes.func,
  scrollToComment: PropTypes.shape({
    id: PropTypes.number,
    page: PropTypes.number,
    y: PropTypes.number
  }),
  onIconMoved: PropTypes.func,
  setPdfReadyToShow: PropTypes.func,
  prefetchFiles: PropTypes.arrayOf(PropTypes.string),
  handleSelectCommentIcon: PropTypes.func
};
