import React, { PropTypes } from 'react';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import PDFJSAnnotate from 'pdf-annotate.js';

import CommentIcon from './CommentIcon';

// The Pdf component encapsulates PDFJS to enable easy rendering of PDFs.
// The component will speed up rendering by only rendering pages when
// they become visible.
export default class Pdf extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      numPages: 0,
      pdfjsPages: [],
      isRendered: []
    };

    PDFJS.workerSrc = this.props.pdfWorker;
    this.setupPdf(this.props.file);
  }

  setIsRendered = (index, value) => {
    this.setState({
      isRendered: [
        ...this.state.isRendered.slice(0, index),
        value,
        ...this.state.isRendered.slice(index + 1)
      ]
    });
  }

  rerenderPage = (index) => {
    if (this.state.isRendered && this.state.isRendered[index]) {
      this.setIsRendered(index, false);
      this.renderPage(index);
    }
  }

  renderPage = (index) => {
    // If we've already rendered the page return.
    if (this.isRendering[index] || index >= this.state.pdfjsPages.length) {
      return new Promise((resolve) => {
        resolve();
      });
    }

    const { UI } = PDFJSAnnotate;
    let RENDER_OPTIONS = {
      documentId: this.props.documentId,
      pdfDocument: this.state.pdfDocument,
      rotate: 0,
      scale: this.props.scale
    };

    this.isRendering[index] = true;

    return new Promise((resolve, reject) => {
      // Call into PDFJSAnnotate to render this page
      UI.renderPage(index + 1, RENDER_OPTIONS).then(() => {
        // If successful then we want to setup a click handler
        let pageContainer = document.getElementById(`pageContainer${index + 1}`);
        pageContainer.addEventListener('click', this.onPageClick(index + 1));

        debugger;
        this.setIsRendered(index, this.props.file);
        resolve();
      }).
      catch(() => {
        // If unsuccessful we want to mark this page as not rendering
        this.isRendering[index] = false;
        reject();
      });
    });
  }

  onPageClick = (pageNumber) => (event) => {
    if (this.props.onPageClick) {

      this.props.onPageClick(
        pageNumber,
        this.getCommentCoordinatesFromEvent(event)
      );
    }
  }

  getCommentCoordinatesFromEvent = (event) => {
    let xPosition = (event.offsetX + event.target.offsetLeft) / this.props.scale;
    let yPosition = (event.offsetY + event.target.offsetTop) / this.props.scale;

    return {
      xPosition,
      yPosition
    };
  }

  createPages = (pdfDocument) => {
    const { UI } = PDFJSAnnotate;
    let pdfjsPages = [];

    for (let i = 0; i < pdfDocument.pdfInfo.numPages; i++) {
      let page = UI.createPage(i + 1);

      pdfjsPages.push(page);
    }

    this.setState({ pdfjsPages });
  }

  scrollEvent = () => {
    let page = document.getElementsByClassName('page');
    let scrollWindow = document.getElementById('scrollWindow');

    Array.prototype.forEach.call(page, (ele, index) => {
      let boundingRect = ele.getBoundingClientRect();

      // You are on this page, if the top of the page is above the middle
      // and the bottom of the page is below the middle
      if (this.props.onPageChange &&
          boundingRect.top < scrollWindow.clientHeight / 2 &&
          boundingRect.bottom > scrollWindow.clientHeight / 2) {
        this.props.onPageChange(index + 1, this.state.numPages);
      }

      // This renders each page as it comes into view. i.e. when
      // the top of the next page is within a thousand pixels of
      // the current view we render it. If the bottom of the page
      // above is within a thousand pixels of the current view
      // we also redner it.
      // TODO: Make this more robust and avoid magic numbers.
      if (boundingRect.bottom > -1000 &&
          boundingRect.top < scrollWindow.clientHeight + 1000) {
        this.renderPage(index);
      }
    });
  }

  // This method sets up the PDF. It sends a web request for the file
  // and when it receives it, starts to render it.
  setupPdf = (file, scrollLocation = 0) => {
    return new Promise((resolve) => {
      this.setState({
        isRendered: []
      });
      PDFJS.getDocument(file).then((pdfDocument) => {
        // Setup isRendered array that tracks whether a given page has been rendered.
        // This way as we scroll we know if we need to render a page that
        // has just come into view.
        this.isRendering = new Array(pdfDocument.pdfInfo.numPages);

        this.setState({
          isRendered: new Array(pdfDocument.pdfInfo.numPages),
          numPages: pdfDocument.pdfInfo.numPages,
          pdfDocument
        }, () => {
          // Create but do not render all of the pages
          this.createPages(pdfDocument);
          resolve();
        });

        if (this.props.onPageChange) {
          this.props.onPageChange(1, pdfDocument.pdfInfo.numPages);
        }

        // Scroll to the correct location on the page
        document.getElementById('scrollWindow').scrollTop = scrollLocation;
      });
    });
  }

  // Consider moving this down into Pdf.jsx
  onJumpToComment = (comments, uuid) => {
    let comment = comments.filter((comment => comment.id === uuid));

    if (comment.length === 1) {
      let pageNumber = comment[0].page;  
      let yPosition = comment[0].y;

      this.renderPage(pageNumber - 1).then(() => {
        let pageElement = document.getElementById(`pageContainer${pageNumber}`);
        let scrollWindow = document.getElementById('scrollWindow');

        let height = (scrollWindow.getBoundingClientRect().bottom -
          scrollWindow.getBoundingClientRect().top);

        scrollWindow.scrollTop =
          pageElement.getBoundingClientRect().top +
          yPosition + scrollWindow.scrollTop - height / 2;
      });
    } else {
      throw new Error(`Cannot scroll to comment ${uuid}`);
    }
  }

  onCommentClick = (event) => {
    this.props.onCommentClick(parseInt(event.getAttribute('data-pdf-annotate-id'), 10));
  }

  componentDidMount = () => {
    
    // Scroll event to render pages as they come into view
    let scrollWindow = document.getElementById('scrollWindow');

    scrollWindow.addEventListener('scroll', this.scrollEvent);
  }

  componentDidUpdate = (_prevProps, prevState) => {
    if (this.state.pdfjsPages !== prevState.pdfjsPages) {
      this.renderPage(0);
      this.onJumpToComment(this.props.comments, this.props.scrollToComment);
    }
  }

  // Calculates the symmetric difference between two sets.
  // The symmetric difference are all the elements that are
  // in exactly one of the sets. (In one but not the other.)
  symmetricDifference = (set1, set2) => {
    let symmetricDifference = new Set();

    set1.forEach((element) => {
      if (!set2.has(element)) {
        symmetricDifference.add(element);
      }
    });

    set2.forEach((element) => {
      if (!set1.has(element)) {
        symmetricDifference.add(element);
      }
    });

    return symmetricDifference;
  }

  componentWillReceiveProps(nextProps) {
    // In general I think this is a good lint rule. However,
    // I think the below statements are clearer
    // with negative conditions.
    /* eslint-disable no-negated-condition */
    if (nextProps.file !== this.props.file) {
      document.getElementById('scrollWindow').scrollTop = 0;
      this.setupPdf(nextProps.file);
    } else if (nextProps.scale !== this.props.scale) {
      // The only way to scale the PDF is to re-render it,
      // so we call setupPdf again.
      this.setupPdf(nextProps.file);
    } else {
      // Determine which comments have changed, and
      // rerender the pages the changed comments are on.
      // The symmetric difference gives us which comments
      // were added or removed.
      let symmetricDifference = this.symmetricDifference(
        new Set(nextProps.comments.map((comment) => comment.uuid)),
        new Set(this.props.comments.map((comment) => comment.uuid)));

      let pagesToUpdate = new Set();
      let allComments = [...nextProps.comments, ...this.props.comments];

      // Find the pages for the added/removed comments
      symmetricDifference.forEach((uuid) => {
        let page = allComments.filter((comment) => comment.uuid === uuid)[0].page;

        pagesToUpdate.add(page);
      });

      // Rerender all these pages to add/remove the comment boxes as necessary.
      pagesToUpdate.forEach((page) => {
        let index = page - 1;

        this.rerenderPage(index);
      });
    }


    // if (nextProps.scrollToComment !== this.props.scrollToComment) {
    //   this.onJumpToComment(nextProps.comments, nextProps.scrollToComment);
    // }

    /* eslint-enable no-negated-condition */
  }

  componentDidUpdate = (prevProps) => {
    if (this.props.scrollToComment && this.props.scrollToComment !== prevProps.scrollToComment) {
      this.onJumpToComment(this.props.comments, this.props.scrollToComment);
    }
  }

  // Record the start coordinates of a drag
  onCommentDragStart = (uuid, page, event) => {
    this.draggingComment = {
      uuid,
      page,
      startCoordinates: {
        x: event.screenX,
        y: event.screenY
      }
    };
  }

  // Move the comment when it's dropped on a page
  onCommentDrop = (event) => {
    event.preventDefault();

    let scaledchangeInCoordinates = {
      deltaX: (event.screenX - this.draggingComment.startCoordinates.x) /
        this.props.scale,
      deltaY: (event.screenY - this.draggingComment.startCoordinates.y) /
        this.props.scale
    };

    this.props.onIconMoved(this.draggingComment.uuid, scaledchangeInCoordinates);
    this.draggingComment = null;
  }

  onPageDragOver = (pageIndex) => (event) => {
    // If the user is dragging a comment over the page the comment is on,
    // we preventDefault in order to allow drops on that page.
    // PreventDefault on dragOver event handlers mean this component can be
    // dropped on. The cursor will display a + icon over droppable components.
    // We only want the current page to be droppable.
    if (pageIndex + 1 === this.draggingComment.page) {
      event.preventDefault();
    }
  }

  render() {
    let commentIcons = this.props.comments.reduce((acc, comment) => {
      // Only show comments on a page if it's been rendered
      if (this.state.isRendered[comment.page] !== this.props.file) {
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
          onClick={this.props.onCommentClick}
          onDragStart={this.onCommentDragStart} />);

      return acc;
    }, {});

    let pages = this.state.pdfjsPages.map((page, index) => {
      return <div
        className="cf-pdf-pdfjs-container"
        onDragOver={this.onPageDragOver(index)}
        onDrop={this.onCommentDrop}
        key={index} >
          <div
            id={`page${index}`}
            dangerouslySetInnerHTML={{ __html: page.outerHTML }}
          />
          <div>
            {commentIcons[index + 1]}
          </div>
        </div>;
    });

    return <div id="scrollWindow" className="cf-pdf-scroll-view">
        <div
          id={this.props.id}
          className={`cf-pdf-page pdfViewer singlePageView`}>
          {pages}
        </div>
      </div>;
  }
}

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
  documentId: PropTypes.number.isRequired,
  file: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  pdfWorker: PropTypes.string.isRequired,
  scale: PropTypes.number,
  onPageClick: PropTypes.func,
  onPageChange: PropTypes.func,
  onCommentClick: PropTypes.func,
  scrollToComment: PropTypes.number,
  onIconMoved: PropTypes.func
};
