/* eslint-disable max-lines */

import React from 'react';
import PropTypes from 'prop-types';

import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import { bindActionCreators } from 'redux';
import { isUserEditingText, pageNumberOfPageIndex, pageIndexOfPageNumber,
  getPageCoordinatesOfMouseEvent, pageCoordsOfRootCoords } from '../reader/utils';
import CommentLayer from '../reader/CommentLayer';
import PdfPage from '../reader/PdfPage';
import { connect } from 'react-redux';
import _ from 'lodash';
import classNames from 'classnames';
import { setPdfReadyToShow, setPageCoordBounds,
  placeAnnotation, requestMoveAnnotation, startPlacingAnnotation,
  stopPlacingAnnotation, showPlaceAnnotationIcon, hidePlaceAnnotationIcon,
  onScrollToComment } from '../reader/actions';
import { ANNOTATION_ICON_SIDE_LENGTH } from '../reader/constants';
import { CATEGORIES, INTERACTION_TYPES } from '../reader/analytics';

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
const TIMEOUT_FOR_GET_DOCUMENT = 100;

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
      isDrawn: {},
      pageDimensions: {}
    };

    this.scrollLocation = {
      page: null,
      locationOnPage: 0
    };

    this.currentPage = 0;
    this.isDrawing = {};
    this.isGettingPdf = {};
    this.loadingTasks = {};

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
    console.log('drawing page', file, index);
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

          console.log('exiting here', file, index);
          console.log(this.pageElements);

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

  postDraw = (resolve, reject, { pdfDocument, scale, index, file }) => {
    this.setisDrawn(file, index, {
      pdfDocument,
      scale
    });

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
    catch(() => {
      this.drawInViewPages();
    });
  }

  performFunctionOnEachPage = (func) => {
    _.forEach(this.pageElements[this.props.file], (ele, index) => {
      if (ele.pageContainer) {
        const boundingRect = ele.pageContainer.getBoundingClientRect();

        func(boundingRect, Number(index));
      }
    });
  }

  setPageDimensions = (pdfDocument, file) => {
    // This is the scale we calculate the page dimensions at. This way we can calculate the
    // page sizes at any scale by multiplying by the value passed in to this.props.scale.
    const PAGE_DIMENSION_SCALE = 1;

    let pageDimensions = [];
    const setStateWithDimensions = () => {
      // Since these promises will finish asynchronously, we need to check if this
      // iteration is the last. If so, then we should set the state with the page
      // dimensions just calculated.
      const numDimensionsFound = pageDimensions.reduce((acc, page) => acc + (page ? 1 : 0), 0);

      if (numDimensionsFound === pdfDocument.pdfInfo.numPages) {
        this.setState({
          pageDimensions: {
            ...this.state.pageDimensions,
            [file]: pageDimensions
          }
        });
      }
    };

    _.range(pdfDocument.pdfInfo.numPages).forEach((pageIndex) => {
      pdfDocument.getPage(pageNumberOfPageIndex(pageIndex)).then((pdfPage) => {
        const viewport = pdfPage.getViewport(PAGE_DIMENSION_SCALE);

        pageDimensions[pageIndex] = _.pick(viewport, ['width', 'height']);
        setStateWithDimensions();
      }).
      catch(() => {
        pageDimensions[pageIndex] = {
          width: PAGE_WIDTH,
          height: PAGE_HEIGHT
        };
        setStateWithDimensions();
      });
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

        this.setPageDimensions(pdfDocument, file);

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
    if (!this.pageElements[file]) {
      this.pageElements[file] = {};
    }
    if (!this.isDrawing[file]) {
      this.isDrawing[file] = _.range(pdfDocument.pdfInfo.numPages).map(() => false);
    }

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

  // This method is a wrapper around PDFJS's getDocument function. We wrap that function
  // so that we can call this whenever we need a reference to the document at the location
  // specified by `file`. This method will only make the request to the server once. Afterwards
  // it will return a cached version of it.
  getDocument = (file) => {
    const pdfsToKeep = [...this.props.prefetchFiles, this.props.file];

    if (!pdfsToKeep.includes(file)) {
      return Promise.resolve(null);
    }

    if (_.get(this.predrawnPdfs, [file, 'pdfDocument'])) {
      // If the document has already been retrieved, just return it.
      return Promise.resolve(this.predrawnPdfs[file].pdfDocument);
    } else if (this.isGettingPdf[file]) {
      // If the document is currently being retrieved we wait until it is, then return it.
      return new Promise((resolve) => {
        return setTimeout(() => {
          this.getDocument(file).then((pdfDocument) => {
            resolve(pdfDocument);
          });
        }, TIMEOUT_FOR_GET_DOCUMENT);
      });
    }

    // If the document has not been retrieved yet, we make a request to the server and
    // set isGettingPdf true so that we don't try to request it again, while the first
    // request is finishing.
    this.isGettingPdf[file] = true;
    this.loadingTasks[file] = PDFJS.getDocument({
      url: file,
      withCredentials: true
    });

    return this.loadingTasks[file].then((pdfDocument) => {
      this.loadingTasks[file] = null;
      this.isGettingPdf[file] = false;

      if ([...this.props.prefetchFiles, this.props.file].includes(file)) {
        // There is a chance another async call has resolved in the time that
        // getDocument took to run. If so, again just use the cached version.
        if (_.get(this.predrawnPdfs, [file, 'pdfDocument'])) {
          pdfDocument.destroy();

          return this.predrawnPdfs[file].pdfDocument;
        }
        this.predrawnPdfs[file] = {
          pdfDocument
        };
        this.setUpPdfObjects(file, pdfDocument);

        return pdfDocument;
      }
      pdfDocument.destroy();

      return null;
    }).
    catch(() => {
      this.isGettingPdf[file] = false;

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
    this.props.onPageChange(
      currentPage,
      this.state.numPages[this.props.file],
      this.scrollWindow.offsetHeight / unscaledHeight);
  }

  handleAltC = () => {
    this.props.startPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);

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
      this.props.stopPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);
    }
  }

  mouseListener = (event) => {
    if (this.props.isPlacingAnnotation) {
      const pageIndex = _(this.pageElements[this.props.file]).
        map('pageContainer').
        indexOf(event.currentTarget);
      const pageCoords = getPageCoordinatesOfMouseEvent(
        event,
        event.currentTarget.getBoundingClientRect(),
        this.props.scale
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

  componentWillUnmount() {
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

      Object.keys(this.predrawnPdfs).forEach((file) => {
        if (!pdfsToKeep.includes(file)) {
          this.cleanUpPdf(this.predrawnPdfs[file], file);
        }
      });

      Object.keys(this.loadingTasks).forEach((file) => {
        if (!pdfsToKeep.includes(file) && this.loadingTasks[file]) {
          this.loadingTasks[file].destroy();
          delete this.loadingTasks[file];
        }
      });

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

    // Wait until the page dimensions have been calculated, then it is
    // safe to jump to the pages since their positioning won't change.
    if (this.state.pageDimensions[this.props.file]) {
      if (this.props.jumpToPageNumber) {
        this.scrollToPage(this.props.jumpToPageNumber);
        this.onPageChange(this.props.jumpToPageNumber);
      }
      if (this.props.scrollToComment) {
        this.scrollToPageLocation(pageIndexOfPageNumber(this.props.scrollToComment.page),
          this.props.scrollToComment.y);
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
  // eslint-disable-next-line max-statements
  onCommentDrop = (pageNumber) => (event) => {
    const dragAndDropPayload = event.dataTransfer.getData('text');
    let dragAndDropData;

    // Anything can be dragged and dropped. If the item that was
    // dropped doesn't match what we expect, we just silently ignore it.
    const logInvalidDragAndDrop = () => window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'invalid-drag-and-drop');

    try {
      dragAndDropData = JSON.parse(dragAndDropPayload);

      if (!dragAndDropData.iconCoordinates || !dragAndDropData.uuid) {
        logInvalidDragAndDrop();

        return;
      }
    } catch (err) {
      if (err instanceof SyntaxError) {
        logInvalidDragAndDrop();

        return;
      }
      throw err;
    }

    let pageBox = document.getElementById(`pageContainer${pageNumber}`).
      getBoundingClientRect();

    let coordinates = {
      x: (event.pageX - pageBox.left - dragAndDropData.iconCoordinates.x) / this.props.scale,
      y: (event.pageY - pageBox.top - dragAndDropData.iconCoordinates.y) / this.props.scale
    };

    const droppedAnnotation = {
      ...this.props.allAnnotations[dragAndDropData.uuid],
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

  getPageContainerRef = (index, file, elem) => {
    if (elem) {
      _.set(this.pageElements[file], [index, 'pageContainer'], elem);
    } else {    
      delete this.pageElements[file][index];
    }
  }

  getCanvasRef = (index, file, elem) => {
    if (elem) {    
      _.set(this.pageElements[file], [index, 'canvas'], elem);
    } else {    
      delete this.pageElements[file][index];
    }
  }

  getTextLayerRef = (index, file, elem) => {
    if (elem) {    
      _.set(this.pageElements[file], [index, 'textLayer'], elem);
    } else {    
      delete this.pageElements[file][index];
    }
  }

  // eslint-disable-next-line max-statements
  render() {
    const pages = _.map(this.state.numPages, (numPages, file) => {
      return _.range(numPages).map((page, pageIndex) => {
        return <PdfPage
            currentFile={this.props.file}
            file={file}
            pageIndex={pageIndex}
            isVisible={this.props.file === file}
            scale={this.props.scale}
            getPageContainerRef={this.getPageContainerRef}
            getCanvasRef={this.getCanvasRef}
            getTextLayerRef={this.getTextLayerRef}
            isDrawn={this.state.isDrawn}
            pageDimensions={this.state.pageDimensions}
          />;
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

const mapStateToProps = (state) => ({
  ...state.readerReducer.ui.pdf,
  ..._.pick(state.readerReducer, 'placingAnnotationIconPageCoords'),
  allAnnotations: state.readerReducer.annotations
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
    onScrollToComment,
    setPdfReadyToShow
  }, dispatch)
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
  prefetchFiles: PropTypes.arrayOf(PropTypes.string)
};
