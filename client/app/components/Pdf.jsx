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
import { ANNOTATION_ICON_SIDE_LENGTH } from '../reader/constants';
import { makeGetAnnotationsByDocumentId } from '../reader/selectors';

const pageNumberOfPageIndex = (pageIndex) => pageIndex + 1;
const pageIndexOfPageNumber = (pageNumber) => pageNumber - 1;

/**
 * We do a lot of work with coordinates to render PDFs.
 * It is important to keep the various coordinate systems straight.
 * Here are the systems we use:
 *
 *    Root coordinates: The coordinate system for the entire app.
 *      (0, 0) is the top left hand corner of the entire HTML document that the browser has rendered.
 *
 *    Page coordinates: A coordinate system for a given PDF page.
 *      (0, 0) is the top left hand corner of that PDF page.
 *
 * The relationship between root and page coordinates is defined by where the PDF page is within the whole app,
 * and what the current scale factor is.
 *
 * All coordinates in our codebase should have `page` or `root` in the name, to make it clear which
 * coordinate system they belong to. All converting between coordinate systems should be done with
 * the proper helper functions.
 */
export const pageCoordsOfRootCoords = ({ x, y }, pageBoundingBox, scale) => ({
  x: (x - pageBoundingBox.left) / scale,
  y: (y - pageBoundingBox.top) / scale
});

export const getInitialAnnotationIconPageCoords = (iconPageBoundingBox, scrollWindowBoundingRect, scale) => {
  const leftBound = Math.max(scrollWindowBoundingRect.left, iconPageBoundingBox.left);
  const rightBound = Math.min(scrollWindowBoundingRect.right, iconPageBoundingBox.right);
  const topBound = Math.max(scrollWindowBoundingRect.top, iconPageBoundingBox.top);
  const bottomBound = Math.min(scrollWindowBoundingRect.bottom, iconPageBoundingBox.bottom);

  const rootCoords = {
    x: _.mean([leftBound, rightBound]),
    y: _.mean([topBound, bottomBound])
  };

  const pageCoords = pageCoordsOfRootCoords(rootCoords, iconPageBoundingBox, scale);

  const annotationIconOffset = ANNOTATION_ICON_SIDE_LENGTH / 2;

  return {
    x: pageCoords.x - annotationIconOffset,
    y: pageCoords.y - annotationIconOffset
  };
};

// This comes from the class .pdfViewer.singlePageView .page in _reviewer.scss.
// We need it defined here to be able to expand/contract margin between pages
// as we zoom.
const PAGE_MARGIN_BOTTOM = 25;

// These both come from _pdf_viewer.css and is the default height
// of the pages in the PDF. We need it defined here to be
// able to expand/contract the height of the pages as we zoom.
const PAGE_WIDTH = 816;
const PAGE_HEIGHT = 1056;

const NUM_PAGES_TO_RENDER_BEFORE_PRERENDERING = 5;
const COVER_SCROLL_HEIGHT = 120;

const NUM_PAGES_TO_PRERENDER = 2;
const MAX_PAGES_TO_RENDER_AT_ONCE = 2;

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

    this.defaultWidth = PAGE_WIDTH;
    this.defaultHeight = PAGE_HEIGHT;

    this.refFunctionGetters = {};

    this.setUpFakeCanvasRefFunctions();
    this.initializePrerendering();
    this.initializeRefs();
  }

  initializeRefs = () => {
    this.pageElements = [];
    this.fakeCanvas = [];
    this.scrollWindow = null;
  }

  initializePrerendering = () => {
    this.prerenderedPdfs = {};
    this.isPrerendering = false;
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
      this.renderInViewPages();

      return Promise.resolve();
    }

    let pdfDocument = this.state.pdfDocument;
    let { scale } = this.props;

    // Mark that we are rendering this page.
    this.isRendering[index] = true;

    return new Promise((resolve, reject) => {
      if (index >= this.state.numPages || pdfDocument !== this.state.pdfDocument) {
        this.isRendering[index] = false;
        this.renderInViewPages();

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

        this.postRender(
          resolve,
          reject,
          {
            pdfDocument,
            canvas,
            scale,
            index,
            viewport
          });
      }).
      catch(() => {
        this.isRendering[index] = false;
        reject();
      });
    });
  }

  postRender = (resolve, reject, { pdfDocument, canvas, scale, index, viewport }) => {
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

      // Since we don't know a page's size until we render it, we either use the
      // naive constants of PAGE_WIDTH and PAGE_HEIGHT for the page dimensions
      // or the dimensions of the first page we successfully render. This allows
      // us to accurately represent the size of pages we haven't rendered yet.
      if (this.defaultWidth === PAGE_WIDTH && this.defaultHeight === PAGE_HEIGHT) {
        this.defaultWidth = viewport.width;
        this.defaultHeight = viewport.height;
      }

      // Whenever we finish rendering a page, we assume that this was the last page
      // to render within the current document. We then try to prerender pages for documents in the
      // prefetchFiles list. The prerenderPages call validates this assumption by
      // checking if any other pages of the current document are being rendered,
      // and will not proceed if they are since we want the current document's pages
      // to take precedence over prerendering other documents' pages.
      this.renderInViewPages();
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
    // If we're already rendering a page, delay this calculation.
    const numberOfPagesRendering = this.isRendering.reduce((acc, rendering) => {
      return acc + (rendering ? 1 : 0);
    }, 0);

    if (numberOfPagesRendering >= MAX_PAGES_TO_RENDER_AT_ONCE) {
      return;
    }

    let prioritzedPage = null;
    let minPageDistance = Number.MAX_SAFE_INTEGER;

    this.performFunctionOnEachPage((boundingRect, index) => {
      // This renders the next "closest" page. Where closest is defined as how
      // far the page is from the viewport.
      if (!this.isRendering[index]) {
        const distanceToCenter = (boundingRect.bottom > 0 && boundingRect.top < this.scrollWindow.clientHeight) ? 0 :
          Math.abs(boundingRect.bottom + boundingRect.top - this.scrollWindow.clientHeight);

        if (!this.state.isRendered[index] || this.state.isRendered[index].scale !== this.props.scale) {
          if (distanceToCenter < minPageDistance) {
            prioritzedPage = index;
            minPageDistance = distanceToCenter;
          }
        }
      }
    });

    // Have to explicitly check for null since prioritizedPage can be zero.
    if (prioritzedPage === null) {
      return;
    }

    this.renderPage(prioritzedPage, this.props.file);
    this.renderInViewPages();
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
            } else {
              delete this.pageElements[index];
            }
          };

          this.refFunctionGetters.canvas[index] = makeSetRef('canvas');
          this.refFunctionGetters.textLayer[index] = makeSetRef('textLayer');
          this.refFunctionGetters.pageContainer[index] = makeSetRef('pageContainer');
        });

        this.defaultWidth = PAGE_WIDTH;
        this.defaultHeight = PAGE_HEIGHT;

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
    const firstPageWithRoomForIconIndex = pageIndexOfPageNumber(this.currentPage);

    const iconPageBoundingBox =
      this.pageElements[firstPageWithRoomForIconIndex].pageContainer.getBoundingClientRect();

    const pageCoords = getInitialAnnotationIconPageCoords(
      iconPageBoundingBox,
      scrollWindowBoundingRect,
      this.props.scale
    );

    this.props.showPlaceAnnotationIcon(firstPageWithRoomForIconIndex, pageCoords);
  }

  handleAltEnter = () => {
    this.props.placeAnnotation(
      pageNumberOfPageIndex(this.props.placingAnnotationIconPageCoords.pageIndex),
      {
        xPosition: this.props.placingAnnotationIconPageCoords.x,
        yPosition: this.props.placingAnnotationIconPageCoords.y
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
    if (this.props.isPlacingAnnotation) {
      const pageIndex = _(this.pageElements).
        map('pageContainer').
        indexOf(event.currentTarget);
      const pageCoords = this.getPageCoordinatesOfMouseEvent(
        event,
        event.currentTarget.getBoundingClientRect()
      );

      this.props.showPlaceAnnotationIcon(pageIndex, pageCoords);
    }
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

    // We want the first few pages of the current document to take precedence over pages
    // on non-visible documents. At the end of rendering pages from this document we always
    // call prerenderPages again in case there are still pages to prerender.
    if (_.some(this.isRendering.slice(0, NUM_PAGES_TO_RENDER_BEFORE_PRERENDERING))) {
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

  // eslint-disable-next-line max-statements
  componentDidUpdate(prevProps) {
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

    const getPropsAffectingPageBounds = (props) => _.omit(props, 'placingAnnotationIconPageCoords', 'scale');

    if (!_.isEqual(
      getPropsAffectingPageBounds(this.props),
      getPropsAffectingPageBounds(prevProps))
    ) {
      this.updatePageBounds();
    }
  }

  /**
   * The page bounds are the upper bounds of the page in the page coordinate system.
   */
  updatePageBounds = () => {
    // The first time this method fires, it sets the page bounds to be the PAGE_WIDTH and PAGE_HEIGHT,
    // because that's what the page bounds are before rendering completes. Somehow, this does not
    // cause a problem, so I'm not going to figure out now how to make it fire with the right values.
    // But if you are seeing issues, that could be why.

    // If we knew that all pages would be the same size, then we could just look
    // at the first page, and know that all pages were the same. That would simplify
    // the code, but it is not an assumption we're making at this time.
    const newPageBounds = _(this.pageElements).
      map((pageElem, pageIndex) => {
        const { right, bottom } = pageElem.pageContainer.getBoundingClientRect();
        const pageCoords = pageCoordsOfRootCoords({
          x: right,
          y: bottom
        }, pageElem.pageContainer.getBoundingClientRect(), this.props.scale);

        return {
          pageIndex: Number(pageIndex),
          width: pageCoords.x,
          height: pageCoords.y
        };
      }).
      keyBy('pageIndex').
      value();

    if (_.size(newPageBounds)) {
      this.props.setPageCoordBounds(newPageBounds);
    }
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
    const constrainedRootCoords = {
      x: _.clamp(event.pageX, container.left, container.right - ANNOTATION_ICON_SIDE_LENGTH),
      y: _.clamp(event.pageY, container.top, container.bottom - ANNOTATION_ICON_SIDE_LENGTH)
    };

    return pageCoordsOfRootCoords(constrainedRootCoords, container, this.props.scale);
  }

  // eslint-disable-next-line max-statements
  render() {
    const annotations = this.props.placingAnnotationIconPageCoords && this.props.isPlacingAnnotation ?
      this.props.comments.concat([{
        temporaryId: 'placing-annotation-icon',
        page: this.props.placingAnnotationIconPageCoords.pageIndex + 1,
        isPlacingAnnotationIcon: true,
        ..._.pick(this.props.placingAnnotationIconPageCoords, 'x', 'y')
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

        const { x, y } = this.getPageCoordinatesOfMouseEvent(
          event,
          this.pageElements[pageNumber - 1].pageContainer.getBoundingClientRect()
        );

        this.props.placeAnnotation(pageNumber, {
          xPosition: x,
          yPosition: y
        }, this.props.documentId);
      };

      const relativeScale = this.props.scale / _.get(this.state.isRendered[pageNumber - 1], 'scale', 1);
      const currentWidth = _.get(this.state.isRendered[pageNumber - 1], 'width', this.defaultWidth);
      const currentHeight = _.get(this.state.isRendered[pageNumber - 1], 'height', this.defaultHeight);

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
          height: `${relativeScale * currentHeight}px`,
          verticalAlign: 'top'
        } }
        onDragOver={this.onPageDragOver}
        onDrop={this.onCommentDrop(pageNumber)}
        key={`${this.props.file}-${pageNumber}`}
        onClick={onPageClick}
        id={`pageContainer${pageNumber}`}
        onMouseMove={this.mouseListener}
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
      onScroll={this.scrollEvent}
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
  ..._.pick(state, 'placingAnnotationIconPageCoords'),
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
