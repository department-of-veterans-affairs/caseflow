/* eslint-disable max-lines */

import React from 'react';
import PropTypes from 'prop-types';

import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import { bindActionCreators } from 'redux';
import { keyOfAnnotation } from '../reader/utils';

import CommentIcon from './CommentIcon';
import { connect } from 'react-redux';
import _ from 'lodash';
import classNames from 'classnames';
import { handleSelectCommentIcon, setPdfReadyToShow, placeAnnotation, requestMoveAnnotation } from '../reader/actions';
import { makeGetAnnotationsByDocumentId } from '../reader/selectors';

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

    this.pageElements = [];
    this.fakeCanvas = [];
    this.scrollWindow = null;

    this.getRefFunctions = {};
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

          // Whenever we finish rendering a page, we assume that we have some spare time.
          // We use that spare time to try and prerender pages for documents in the
          // prefetchFiles list. The prerenderPages call checks to see if any other pages
          // of the current document are being rendered, and will not proceed if they are
          // since the current document's pages take precedence over prerendering other
          // documents' pages.
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
      if (boundingRect.top < this.scrollWindow.clientHeight / 2 &&
          boundingRect.bottom > this.scrollWindow.clientHeight / 2) {
        this.onPageChange(index + 1);
      }
    });
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
    this.pageElements.forEach((ele, index) => {
      if (ele.pageContainer) {
        const boundingRect = ele.pageContainer.getBoundingClientRect();

        func(boundingRect, index);
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

        this.pageElements = [];

        this.getRefFunctions.canvas = [];
        this.getRefFunctions.textLayer = [];
        this.getRefFunctions.pageContainer = [];

        _.range(pdfDocument.pdfInfo.numPages).forEach((index) => {
          this.getRefFunctions.canvas[index] = this.makeGetCanvasRef(index);
          this.getRefFunctions.textLayer[index] = this.makeGetTextRef(index);
          this.getRefFunctions.pageContainer[index] = this.makeGetPageContainerRef(index);
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
            resolve();
          });
        });
        this.props.setPdfReadyToShow(this.props.documentId);
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

  componentDidMount = () => {
    PDFJS.workerSrc = this.props.pdfWorker;
    window.addEventListener('resize', this.renderInViewPages);

    this.setUpPdf(this.props.file);
  }

  comopnentWillUnmount = () => {
    window.removeEventListener('resize', this.renderInViewPages);
  }

  setUpFakeCanvasRefFunctions = () => {
    this.getRefFunctions.fakeCanvas = [];

    this.props.prefetchFiles.forEach((_unused, index) => {
      _.range(NUM_PAGES_TO_PRERENDER).forEach((pageIndex) => {
        _.set(this.getRefFunctions, ['fakeCanvas', index, pageIndex], this.makeGetFakeCanvasRef(index, pageIndex));
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


  componentDidUpdate = () => {
    this.renderInViewPages();
    this.prerenderPages();

    if (this.props.scrollToComment) {
      if (this.props.documentId === this.props.scrollToComment.documentId &&
        this.state.pdfDocument && this.props.pdfsReadyToShow[this.props.documentId]) {
        this.onJumpToComment(this.props.scrollToComment);
        this.props.onCommentScrolledTo();
      }
    }

    if (this.scrollLocation.page) {
      this.scrollWindow.scrollTop = this.scrollLocation.locationOnPage +
        this.pageElements[this.scrollLocation.page - 1].pageContainer.offsetTop;
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

  makeGetCanvasRef = (pageNumber) => (canvas) => _.set(this.pageElements, [pageNumber, 'canvas'], canvas)
  makeGetTextRef = (pageNumber) => (textLayer) => _.set(this.pageElements, [pageNumber, 'textLayer'], textLayer)
  makeGetFakeCanvasRef = (index, pageIndex) => (ele) => _.set(this.fakeCanvas, [index, pageIndex], ele)
  makeGetPageContainerRef = (pageNumber) => (pageContainer) =>
    _.set(this.pageElements, [pageNumber, 'pageContainer'], pageContainer)
  getScrollWindowRef = (scrollWindow) => this.scrollWindow = scrollWindow

  // eslint-disable-next-line max-statements
  render() {
    let commentIcons = this.props.comments.reduce((acc, comment) => {
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
          onClick={this.props.handleSelectCommentIcon} />);

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

        let container = this.pageElements[pageNumber - 1].pageContainer.getBoundingClientRect();
        let xPosition = (event.pageX - container.left) / this.props.scale;
        let yPosition = (event.pageY - container.top) / this.props.scale;

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
        ref={this.getRefFunctions.pageContainer[pageNumber - 1]}>
          <div className={pageContentsVisibleClass}>
            <canvas
              id={`canvas${pageNumber}-${this.props.file}`}
              ref={this.getRefFunctions.canvas[pageNumber - 1]}
              className="canvasWrapper" />
            <div className="cf-pdf-annotationLayer">
              {commentIcons[pageNumber]}
            </div>
            <div
              id={`textLayer${pageNumber}`}
              ref={this.getRefFunctions.textLayer[pageNumber - 1]}
              className="textLayer"/>
          </div>
        </div>);
    }

    const prerenderCanvases = this.props.prefetchFiles.map((_unused, index) => {
      return _.range(NUM_PAGES_TO_PRERENDER).map((pageIndex) =>
        <canvas
          style={{ display: 'none' }}
          key={`${pageIndex}-${index}`}
          ref={_.get(this.getRefFunctions.fakeCanvas, [index, pageIndex])}/>
      );
    });

    return <div
      id="scrollWindow"
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
  comments: makeGetAnnotationsByDocumentId(state)(ownProps.documentId),
  allAnnotations: state.annotations
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    placeAnnotation,
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
  onCommentScrolledTo: PropTypes.func,
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
