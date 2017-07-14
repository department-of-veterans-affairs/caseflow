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
  stopPlacingAnnotation, showPlaceAnnotationIcon, hidePlaceAnnotationIcon,
  onScrollToComment } from '../reader/actions';
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

const NUM_PAGES_TO_DRAW_BEFORE_PREDRAWING = 5;
const COVER_SCROLL_HEIGHT = 120;

const NUM_PAGES_TO_PREDRAW = 2;
const MAX_PAGES_TO_DRAW_AT_ONCE = 2;

// The Pdf component encapsulates PDFJS to enable easy drawing of PDFs.
// The component will speed up drawing by only drawing pages when
// they become visible.
export class Pdf extends React.PureComponent {
  constructor(props) {
    super(props);
    // We use two variables to maintain the state of drawing.
    // isDrawing below is outside of the state variable.
    // isDrawing[pageNumber] is true when a page is currently
    // being drawn by PDFJS. It is set to false when drawing
    // is either successful or aborts.
    // isDrawn is in the state variable, since an update to
    // isDrawn should trigger a render update since we need to
    // draw comments after a page is drawn. Once a page is
    // successfully drawn we set isDrawn[pageNumber] to be the
    // filename of the drawn PDF. This way, if PDFs are changed
    // we know which pages are stale.
    this.state = {
      numPages: {},
      pdfDocument: {},
      isDrawn: {}
    };

    this.scrollLocation = {
      page: null,
      locationOnPage: 0
    };

    this.currentPage = 0;
    this.isDrawing = {};

    this.defaultWidth = PAGE_WIDTH;
    this.defaultHeight = PAGE_HEIGHT;

    this.refFunctionGetters = {
      canvas: {},
      textLayer: {},
      pageContainer: {}
    };

    this.initializePredrawing();
    this.initializeRefs();
  }

  initializeRefs = () => {
    this.pageElements = {};
    this.scrollWindow = null;
  }

  initializePredrawing = () => {
    this.predrawnPdfs = {};
    this.isPrerdrawing = false;
  }

  setisDrawn = (file, index, value) => {
    this.isDrawing[file][index] = false;
    let isDrawn = { ...this.state.isDrawn };

    _.set(isDrawn, [file, index], value);

    this.setState({
      isDrawn
    });
  }

  setElementDimensions = (element, dimensions) => {
    element.style.width = `${dimensions.width}px`;
    element.style.height = `${dimensions.height}px`;
  }

  // This method is the worst. It is our main interaction with PDFJS, so it will
  // likey remain complicated.
  drawPage = (file, index) => {
    if (this.isDrawing[file][index] ||
      _.get(this.state.isDrawn, [file, index, 'scale']) === this.props.scale) {

      return Promise.reject();
    }

    const { scale } = this.props;

    // Mark that we are drawing this page.
    this.isDrawing[file][index] = true;

    return new Promise((resolve, reject) => {
      return this.getDocument(file).then((pdfDocument) => {
        // Page numbers are one-indexed
        const pageNumber = index + 1;
        const canvas = _.get(this.pageElements, [file, index, 'canvas'], null);
        const container = _.get(this.pageElements, [file, index, 'textLayer'], null);
        const page = _.get(this.pageElements, [file, index, 'pageContainer'], null);

        if (!canvas || !container || !page) {
          this.isDrawing[file][index] = false;

          return reject();
        }

        return pdfDocument.getPage(pageNumber).then((pdfPage) => {
          // The viewport is a PDFJS concept that combines the size of the
          // PDF pages with the scale go get the dimensions of the divs.
          const viewport = pdfPage.getViewport(this.props.scale);

          // We need to set the width and heights of everything based on
          // the width and height of the viewport.
          canvas.height = viewport.height;
          canvas.width = viewport.width;

          this.setElementDimensions(container, viewport);
          this.setElementDimensions(page, viewport);
          container.innerHTML = '';

          // Call PDFJS to actually draw the page.
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
            container,
            viewport,
            textDivs: []
          });

          this.postDraw(
            resolve,
            reject,
            {
              pdfDocument,
              scale,
              index,
              viewport,
              file
            });
        }).
        catch(() => {
          this.isDrawing[file][index] = false;
          reject();
        });
      }).
      catch(() => {
        this.isDrawing[file][index] = false;
        reject();
      });
    });
  }

  postDraw = (resolve, reject, { pdfDocument, scale, index, viewport, file }) => {
    this.setisDrawn(file, index, {
      pdfDocument,
      scale,
      ..._.pick(viewport, ['width', 'height'])
    });

    // Since we don't know a page's size until we draw it, we either use the
    // naive constants of PAGE_WIDTH and PAGE_HEIGHT for the page dimensions
    // or the dimensions of the first page we successfully draw. This allows
    // us to accurately represent the size of pages we haven't drawn yet.
    if (this.defaultWidth === PAGE_WIDTH && this.defaultHeight === PAGE_HEIGHT) {
      this.defaultWidth = viewport.width;
      this.defaultHeight = viewport.height;
    }

    resolve();
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

    if (this.props.scrollToComment) {
      this.props.onScrollToComment(null);
    }

    if (this.props.jumpToPageNumber) {
      this.props.resetJumpToPage();
    }
    this.drawInViewPages();
  }

  drawInViewPages = () => {
    // If we're already drawn a page, delay this calculation.
    const numberOfPagesDrawing = _.reduce(this.isDrawing, (total, drawingArray) => {
      return total + drawingArray.reduce((acc, drawing) => {
        return acc + (drawing ? 1 : 0);
      }, 0);
    }, 0);

    if (numberOfPagesDrawing >= MAX_PAGES_TO_DRAW_AT_ONCE) {
      return;
    }

    let prioritzedPage = null;
    let minPageDistance = Number.MAX_SAFE_INTEGER;

    this.performFunctionOnEachPage((boundingRect, index) => {
      // This draws the next "closest" page. Where closest is defined as how
      // far the page is from the viewport.
      if (!this.isDrawing[this.props.file][index]) {
        const distanceToCenter = (boundingRect.bottom > 0 && boundingRect.top < this.scrollWindow.clientHeight) ? 0 :
          Math.abs(boundingRect.bottom + boundingRect.top - this.scrollWindow.clientHeight);

        if (!_.get(this.state, ['isDrawn', this.props.file, index], false) ||
          this.state.isDrawn[this.props.file][index].scale !== this.props.scale) {
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

    this.drawPage(this.props.file, prioritzedPage).then(() => {
      this.drawInViewPages();
      this.preDrawPages();
    }).
    catch();
  }

  performFunctionOnEachPage = (func) => {
    _.forEach(this.pageElements[this.props.file], (ele, index) => {
      if (ele.pageContainer) {
        const boundingRect = ele.pageContainer.getBoundingClientRect();

        func(boundingRect, Number(index));
      }
    });
  }

  // This method sets up the PDF. It sends a web request for the file
  // and when it receives it, starts to draw it.
  setUpPdf = (file) => {
    this.latestFile = file;

    return new Promise((resolve) => {
      this.getDocument(this.latestFile).then((pdfDocument) => {
        // Don't continue seting up the pdf if it's already been set up.
        if (!pdfDocument || pdfDocument === this.state.pdfDocument) {
          return resolve();
        }

        this.defaultWidth = PAGE_WIDTH;
        this.defaultHeight = PAGE_HEIGHT;

        this.setState({
          numPages: {
            ...this.state.numPages,
            [file]: pdfDocument.pdfInfo.numPages
          },
          pdfDocument,
          isDrawn: {
            [file]: [],
            ...this.state.isDrawn
          }
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

  setUpPdfObjects = (file, pdfDocument) => {
    this.pageElements[file] = {};

    if (!this.isDrawing[file]) {
      this.isDrawing[file] = _.range(pdfDocument.pdfInfo.numPages).map(() => false);
    }

    this.refFunctionGetters.canvas[file] = [];
    this.refFunctionGetters.textLayer[file] = [];
    this.refFunctionGetters.pageContainer[file] = [];

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
          _.set(this.pageElements[file], [index, elemKey], elem);
        } else {
          delete this.pageElements[file][index];
        }
      };

      this.refFunctionGetters.canvas[file][index] = makeSetRef('canvas');
      this.refFunctionGetters.textLayer[file][index] = makeSetRef('textLayer');
      this.refFunctionGetters.pageContainer[file][index] = makeSetRef('pageContainer');
    });

    this.setState({
      numPages: {
        ...this.state.numPages,
        [file]: pdfDocument.pdfInfo.numPages
      },
      isDrawn: {
        [file]: [],
        ...this.state.isDrawn
      }
    });
  }

  getDocument = (file) => {
    if (_.get(this.predrawnPdfs, [file, 'pdfDocument'])) {
      return Promise.resolve(this.predrawnPdfs[file].pdfDocument);
    }

    return PDFJS.getDocument(file).then((pdfDocument) => {
      if ([...this.props.prefetchFiles, this.props.file].includes(file)) {
        // There is a chance another async call has resolved in the time that
        // getDocument took to run. If so, again just use the cached version.
        if (_.get(this.predrawnPdfs, [file, 'pdfDocument'])) {
          return this.predrawnPdfs[file].pdfDocument;
        }
        this.predrawnPdfs[file] = {
          pdfDocument
        };
        this.setUpPdfObjects(file, pdfDocument);

        return pdfDocument;
      }

      return null;
    });
  }

  scrollToPageLocation = (pageIndex, yPosition = 0) => {
    if (this.pageElements[this.props.file]) {
      const boundingBox = this.scrollWindow.getBoundingClientRect();
      const height = (boundingBox.bottom - boundingBox.top);
      const halfHeight = height / 2;

      this.scrollWindow.scrollTop =
        this.pageElements[this.props.file][pageIndex].pageContainer.getBoundingClientRect().top +
        yPosition + this.scrollWindow.scrollTop - halfHeight;

      return true;
    }

    return false;
  }

  onPageChange = (currentPage) => {
    const unscaledHeight = (_.get(this.pageElements,
      [this.props.file, currentPage - 1, 'pageContainer', 'offsetHeight']) / this.props.scale);

    this.currentPage = currentPage;
    console.log(currentPage, this.state.numPages[this.props.file], this.scrollWindow.offsetHeight / unscaledHeight)
    this.props.onPageChange(
      currentPage,
      this.state.numPages[this.props.file],
      this.scrollWindow.offsetHeight / unscaledHeight);
  }

  handleAltC = () => {
    this.props.startPlacingAnnotation();

    const scrollWindowBoundingRect = this.scrollWindow.getBoundingClientRect();
    const firstPageWithRoomForIconIndex = pageIndexOfPageNumber(this.currentPage);

    const iconPageBoundingBox =
      this.pageElements[this.props.file][firstPageWithRoomForIconIndex].pageContainer.getBoundingClientRect();

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
      const pageIndex = _(this.pageElements[this.props.file]).
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
    window.addEventListener('resize', this.drawInViewPages);
    window.addEventListener('keydown', this.keyListener);

    this.setUpPdf(this.props.file);

    // focus the scroll window when the component initially loads.
    this.scrollWindow.focus();
    this.updatePageBounds();
  }

  comopnentWillUnmount() {
    window.removeEventListener('resize', this.drawInViewPages);
    window.removeEventListener('keydown', this.keyListener);
  }

  cleanUpPdf = (pdf, file) => {
    if (pdf.pdfDocument) {
      pdf.pdfDocument.destroy();
    }

    if (this.isDrawing[file]) {
      this.isDrawing[file] = this.isDrawing[file].map(() => false);
    }

    _.forEach(_.get(this.pageElements, [file], []), (pageElement) => {
      const canvas = pageElement.canvas;

      pageElement.textLayer.innerHTML = '';
      canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height);
    });
    this.setState({
      isDrawn: {
        ...this.state.isDrawn,
        [file]: _.get(this.state.isDrawn, ['file'], []).map(() => null)
      }
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
        this.pageElements[this.props.file][this.currentPage - 1].pageContainer.offsetTop);

      this.scrollLocation = {
        page: this.currentPage,
        locationOnPage: nonZoomedLocation * zoomFactor
      };
    }

    if (nextProps.prefetchFiles !== this.props.prefetchFiles) {
      const pdfsToKeep = [...nextProps.prefetchFiles, nextProps.file];

      _.forEach(_.omit(this.predrawnPdfs, pdfsToKeep), this.cleanUpPdf);

      this.predrawnPdfs = _.pick(this.predrawnPdfs, pdfsToKeep);
    }
    /* eslint-enable no-negated-condition */
  }

  preDrawPages = () => {
    const finishPredraw = () => {
      this.isPrerdrawing = false;
      this.preDrawPages();
    };

    // We want the first few pages of the current document to take precedence over pages
    // on non-visible documents. At the end of drawing pages from this document we always
    // call preDrawPages again in case there are still pages to predraw.
    if (this.isDrawing[this.props.file] &&
      _.some(this.isDrawing[this.props.file].slice(0, NUM_PAGES_TO_DRAW_BEFORE_PREDRAWING))) {
      return;
    }

    this.props.prefetchFiles.forEach((file) => {
      this.getDocument(file).then((pdfDocument) => {
        if (pdfDocument) {
          _.range(NUM_PAGES_TO_PREDRAW).forEach((pageIndex) => {
            if (pageIndex < pdfDocument.pdfInfo.numPages &&
              !_.get(this.state, ['isDrawn', file, pageIndex]) &&
              !this.isPrerdrawing) {
              this.isPrerdrawing = true;

              this.drawPage(file, pageIndex).then(finishPredraw).
                catch(() => this.isPrerdrawing = false);
            }
          });
        }
      });
    });
  }

  scrollToPage(pageNumber) {
    this.scrollWindow.scrollTop =
      this.pageElements[this.props.file][pageNumber - 1].pageContainer.getBoundingClientRect().top +
      this.scrollWindow.scrollTop - COVER_SCROLL_HEIGHT;
  }

  // eslint-disable-next-line max-statements
  componentDidUpdate(prevProps) {
    this.drawInViewPages();
    this.preDrawPages();

    // if jump to page number is provided
    // draw the page and jump to the page
    if (this.props.jumpToPageNumber) {
      this.scrollToPage(this.props.jumpToPageNumber);
      this.onPageChange(this.props.jumpToPageNumber);
    }
    if (this.props.scrollToComment) {
      if (this.props.documentId === this.props.scrollToComment.documentId) {
        this.scrollToPageLocation(pageIndexOfPageNumber(this.props.scrollToComment.page), this.props.scrollToComment.y);
      }
    }

    if (this.scrollLocation.page) {
      this.scrollWindow.scrollTop = this.scrollLocation.locationOnPage +
        this.pageElements[this.props.file][this.scrollLocation.page - 1].pageContainer.offsetTop;
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
    // because that's what the page bounds are before drawing completes. Somehow, this does not
    // cause a problem, so I'm not going to figure out now how to make it fire with the right values.
    // But if you are seeing issues, that could be why.

    // If we knew that all pages would be the same size, then we could just look
    // at the first page, and know that all pages were the same. That would simplify
    // the code, but it is not an assumption we're making at this time.
    const newPageBounds = _(this.pageElements[this.props.file]).
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
      // Only show comments on a page if it's been drawn
      if (_.get(this.state.isDrawn, [this.props.file, comment.page - 1, 'pdfDocument']) !==
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

    const pageClassNames = classNames({
      'cf-pdf-pdfjs-container': true,
      page: true,
      'cf-pdf-placing-comment': this.props.isPlacingAnnotation
    });

    const pages = _.map(this.state.numPages, (numPages, file) => {
      return _.range(numPages).map((page, pageIndex) => {
        const onPageClick = (event) => {
          if (!this.props.isPlacingAnnotation) {
            return;
          }

          const { x, y } = this.getPageCoordinatesOfMouseEvent(
            event,
            this.pageElements[this.props.file][pageIndex].pageContainer.getBoundingClientRect()
          );

          this.props.placeAnnotation(pageIndex + 1, {
            xPosition: x,
            yPosition: y
          }, this.props.documentId);
        };

        const relativeScale = this.props.scale / _.get(this.state.isDrawn, [this.props.file, pageIndex, 'scale'], 1);
        const currentWidth = _.get(this.state.isDrawn, [this.props.file, pageIndex, 'width'], this.defaultWidth);
        const currentHeight = _.get(this.state.isDrawn, [this.props.file, pageIndex, 'height'], this.defaultHeight);

        // Only pages that are the correct scale should be visible
        const CORRECT_SCALE_DELTA_THRESHOLD = 0.01;
        const pageContentsVisibleClass = classNames({
          'cf-pdf-page-hidden': !(Math.abs(relativeScale - 1) < CORRECT_SCALE_DELTA_THRESHOLD)
        });

        return <div
          className={this.props.file === file && pageClassNames}
          style={ {
            marginBottom: `${PAGE_MARGIN_BOTTOM * this.props.scale}px`,
            width: `${relativeScale * currentWidth}px`,
            height: `${relativeScale * currentHeight}px`,
            verticalAlign: 'top',
            display: file === this.props.file ? '' : 'none'
          } }
          onDragOver={this.onPageDragOver}
          onDrop={this.onCommentDrop(pageIndex + 1)}
          key={`${file}-${pageIndex + 1}`}
          onClick={onPageClick}
          id={this.props.file === file && `pageContainer${pageIndex + 1}`}
          onMouseMove={this.mouseListener}
          ref={this.refFunctionGetters.pageContainer[file][pageIndex]}>
            <div className={pageContentsVisibleClass}>
              <canvas
                id={`canvas${pageIndex + 1}-${file}`}
                ref={this.refFunctionGetters.canvas[file][pageIndex]}
                className="canvasWrapper" />
              <div className="cf-pdf-annotationLayer">
                {this.props.file === file && commentIcons[pageIndex + 1]}
              </div>
              <div
                id={`textLayer${pageIndex + 1}`}
                ref={this.refFunctionGetters.textLayer[file][pageIndex]}
                className="textLayer"/>
            </div>
          </div>;
      });
    });

    return <div
      id="scrollWindow"
      tabIndex="0"
      className="cf-pdf-scroll-view"
      onScroll={this.scrollEvent}
      ref={this.getScrollWindowRef}>
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
    requestMoveAnnotation,
    onScrollToComment
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
