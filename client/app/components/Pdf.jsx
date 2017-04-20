import React, { PropTypes } from 'react';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

import CommentIcon from './CommentIcon';
import * as Constants from '../reader/constants';
import { connect } from 'react-redux';
import _ from 'lodash';

// The Pdf component encapsulates PDFJS to enable easy rendering of PDFs.
// The component will speed up rendering by only rendering pages when
// they become visible.
export class Pdf extends React.Component {
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
      numPages: 0,
      pdfDocument: null,
      isRendered: []
    };

    this.isRendering = [];
  }

  setIsRendered = (index, value) => {
    this.isRendering[index] = false;
    this.setState({
      isRendered: [
        ...this.state.isRendered.slice(0, index),
        value,
        ...this.state.isRendered.slice(index + 1)
      ]
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
      this.state.isRendered[index] === this.state.pdfDocument) {
      return Promise.resolve();
    }

    let pdfDocument = this.state.pdfDocument;

    // Mark that we are rendering this page.
    this.isRendering[index] = true;

    return new Promise((resolve, reject) => {
      if (index >= this.state.numPages) {
        resolve();
      }

      // Page numbers are one-indexed
      let pageNumber = index + 1;
      let canvas = document.getElementById(`canvas${pageNumber}`);
      let container = document.getElementById(`textLayer${pageNumber}`);
      let page = this.pageContainers[pageNumber - 1];

      if (!canvas || !container || !page) {
        reject();
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
        // should render this page again with the new file.
        if (pdfDocument === this.state.pdfDocument) {
          // If it is the same, then we mark this page as rendered
          this.setIsRendered(index, pdfDocument);
          resolve();
        } else {
          // If it is not, then we try to render it again.
          this.isRendering[index] = false;
          this.renderPage(index).then(() => {
            resolve();
          }).
          catch(() => {
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

  onPageClick = (pageNumber) => (event) => {
    if (this.props.onPageClick) {
      let container = this.pageContainers[pageNumber - 1].getBoundingClientRect();
      let xPosition = (event.pageX - container.left) / this.props.scale;
      let yPosition = (event.pageY - container.top) / this.props.scale;

      this.props.onPageClick(
        pageNumber,
        {
          xPosition,
          yPosition
        }
      );
    }
  }

  scrollEvent = () => {
    let page = document.getElementsByClassName('page');

    Array.prototype.forEach.call(page, (ele, index) => {
      let boundingRect = ele.getBoundingClientRect();

      // You are on this page, if the top of the page is above the middle
      // and the bottom of the page is below the middle
      if (this.props.onPageChange &&
          boundingRect.top < this.scrollWindow.clientHeight / 2 &&
          boundingRect.bottom > this.scrollWindow.clientHeight / 2) {
        this.props.onPageChange(index + 1, this.state.numPages);
      }

      // This renders each page as it comes into view. i.e. when
      // the top of the next page is within a thousand pixels of
      // the current view we render it. If the bottom of the page
      // above is within a thousand pixels of the current view
      // we also redner it.
      // TODO: Make this more robust and avoid magic numbers.
      if (boundingRect.bottom > -1000 &&
          boundingRect.top < this.scrollWindow.clientHeight + 1000) {
        this.renderPage(index, this.props.file);
      }
    });
  }

  // This method sets up the PDF. It sends a web request for the file
  // and when it receives it, starts to render it.
  setupPdf = (file, scrollLocation = 0) => {
    return new Promise((resolve) => {
      PDFJS.getDocument(file).then((pdfDocument) => {
        this.setState({
          numPages: pdfDocument.pdfInfo.numPages,
          pdfDocument,
          isRendered: []
        }, () => {
          resolve();
        });

        if (this.props.onPageChange) {
          this.props.onPageChange(1, pdfDocument.pdfInfo.numPages);
        }

        this.props.handleSetCurrentRenderedFile(this.props.documentId);

        // Scroll to the correct location on the page
        this.scrollWindow.scrollTop = scrollLocation;
      });
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
          this.pageContainers[pageNumber - 1].getBoundingClientRect().top +
          yPosition + this.scrollWindow.scrollTop - halfHeight;
      });
    }
  }

  onCommentClick = (comment) => () => {
    this.props.onCommentClick(comment.id);
    this.props.handleSelectCommentIcon(comment);
  }

  componentDidMount = () => {
    PDFJS.workerSrc = this.props.pdfWorker;
    this.setupPdf(this.props.file);
  }

  componentWillReceiveProps(nextProps) {
    // In general I think this is a good lint rule. However,
    // I think the below statements are clearer
    // with negative conditions.
    /* eslint-disable no-negated-condition */
    if (nextProps.file !== this.props.file) {
      this.scrollWindow.scrollTop = 0;
      this.setupPdf(nextProps.file);
    } else if (nextProps.scale !== this.props.scale) {
      // The only way to scale the PDF is to re-render it,
      // so we call setupPdf again.
      this.setupPdf(nextProps.file);
    }
    /* eslint-enable no-negated-condition */
  }

  componentDidUpdate = () => {
    for (let index = 0; index < Math.min(5, this.state.numPages); index++) {
      if (!this.state.isRendered[index] && this.pageContainers[index]) {
        this.renderPage(index, this.props.file);
      }
    }

    if (this.props.scrollToComment) {
      if (this.props.currentRenderedFile === this.props.scrollToComment.documentId &&
        this.state.pdfDocument) {
        this.onJumpToComment(this.props.scrollToComment);
        this.props.onCommentScrolledTo();
      }
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

    this.props.onIconMoved(data.uuid, coordinates, pageNumber);
  }

  onPageDragOver = (event) => {
    // The cursor will display a + icon over droppable components.
    // To specify the component as droppable, we need to preventDefault
    // on the event.
    event.preventDefault();
  }

  render() {
    let commentIcons = this.props.comments.reduce((acc, comment) => {
      // Only show comments on a page if it's been rendered
      if (this.state.isRendered[comment.page - 1] !== this.state.pdfDocument) {
        return acc;
      }
      if (!acc[comment.page]) {
        acc[comment.page] = [];
      }
      acc[comment.page].push(
        <CommentIcon
          position={{
            x: comment.x * this.props.scale,
            y: comment.y * this.props.scale
          }}
          key={comment.uuid}
          selected={comment.selected}
          uuid={comment.uuid}
          page={comment.page}
          onClick={this.onCommentClick(comment)} />);

      return acc;
    }, {});

    let pages = [];

    this.pageContainers = [];

    for (let pageNumber = 1; pageNumber <= this.state.numPages; pageNumber++) {
      pages.push(<div
        className="cf-pdf-pdfjs-container page"
        onDragOver={this.onPageDragOver}
        onDrop={this.onCommentDrop(pageNumber)}
        key={`${this.props.file}-${pageNumber}`}
        onClick={this.onPageClick(pageNumber)}
        id={`pageContainer${pageNumber}`}
        ref={(pageContainer) => {
          this.pageContainers[pageNumber - 1] = pageContainer;
        }}>
          <canvas
            id={`canvas${pageNumber}`}
            className="canvasWrapper" />
          <div className="cf-pdf-annotationLayer">
            {commentIcons[pageNumber]}
          </div>
          <div
            id={`textLayer${pageNumber}`}
            className="textLayer"/>
        </div>);
    }
    this.scrollWindow = null;

    return <div
      id="scrollWindow"
      className="cf-pdf-scroll-view"
      onScroll={this.scrollEvent}
      ref={(scrollWindow) => {
        this.scrollWindow = scrollWindow;
      }}>
        <div
          id={this.props.file}
          className={`cf-pdf-page pdfViewer singlePageView`}>
          {pages}
        </div>
      </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    currentRenderedFile: _.get(state, 'ui.pdf.currentRenderedFile'),
    scrollToComment: _.get(state, 'ui.pdf.scrollToComment')
  };
};

const mapDispatchToProps = (dispatch) => ({
  handleSetCurrentRenderedFile(currentRenderedFile) {
    dispatch({
      type: Constants.SET_CURRENT_RENDERED_FILE,
      payload: { currentRenderedFile }
    });
  },
  handleSelectCommentIcon(comment) {
    dispatch({
      type: Constants.SCROLL_TO_SIDEBAR_COMMENT,
      payload: { 
        scrollToSidebarComment: comment
      }
    });
  }
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(Pdf);


Pdf.defaultProps = {
  scale: 1
};

Pdf.propTypes = {
  comments: PropTypes.arrayOf(PropTypes.shape({
    comment: PropTypes.string,
    uuid: PropTypes.number,
    page: PropTypes.number,
    x: PropTypes.number,
    y: PropTypes.number
  })),
  currentRenderedFile: PropTypes.number,
  documentId: PropTypes.number.isRequired,
  file: PropTypes.string.isRequired,
  handleSetCurrentRenderedFile: PropTypes.func.isRequired,
  pdfWorker: PropTypes.string.isRequired,
  scale: PropTypes.number,
  onPageClick: PropTypes.func,
  onPageChange: PropTypes.func,
  onCommentClick: PropTypes.func,
  onCommentScrolledTo: PropTypes.func,
  scrollToComment: PropTypes.shape({
    id: React.PropTypes.number,
    page: React.PropTypes.number,
    y: React.PropTypes.number
  }),
  onIconMoved: PropTypes.func,
  handleSelectCommentIcon: PropTypes.func
};
