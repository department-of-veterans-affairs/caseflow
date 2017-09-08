import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import _ from 'lodash';

import { makeGetAnnotationsByDocumentId } from '../reader/selectors';
import CommentIcon from './CommentIcon';
import { keyOfAnnotation, pageNumberOfPageIndex, getPageCoordinatesOfMouseEvent } from './utils';
import { handleSelectCommentIcon, placeAnnotation,
  requestMoveAnnotation, showPlaceAnnotationIcon } from '../reader/actions';
import { CATEGORIES } from '../reader/analytics';

const DIV_STYLING = {
  width: '100%',
  height: '100%',
  zIndex: 10,
  position: 'relative'
};

// The comment layer is a div on top of a page that draws the comment
// icons on the page. It is the div that receives the onClick
// events when placing new comments. It is also the div that displays
// the PDF text elements. We need text elements in this div since it
// is the largest zIndex div, and blocks lower divs from receiving click events.
// The text layer needs to be click-able so users can highlight/copy/paste them.
class CommentLayer extends PureComponent {
  constructor(props) {
    super(props);

    this.commentLayerDiv = null;
  }

  onPageClick = (event) => {
    if (!this.props.isPlacingAnnotation) {
      return;
    }

    const { x, y } = getPageCoordinatesOfMouseEvent(
      event,
      this.commentLayerDiv.getBoundingClientRect(),
      this.props.scale
    );

    this.props.placeAnnotation(
      pageNumberOfPageIndex(this.props.pageIndex),
      {
        xPosition: x,
        yPosition: y
      },
      this.props.documentId
    );
  };

  getPlacingAnnotation = () => {
    if (this.props.placingAnnotationIconPageCoords && this.props.isPlacingAnnotation) {
      return [{
        temporaryId: 'placing-annotation-icon',
        page: pageNumberOfPageIndex(this.props.placingAnnotationIconPageCoords.pageIndex),
        isPlacingAnnotationIcon: true,
        ..._.pick(this.props.placingAnnotationIconPageCoords, 'x', 'y')
      }];
    }

    return [];

  }
  // Move the comment when it's dropped on a page
  // eslint-disable-next-line max-statements
  onCommentDrop = (event) => {
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

    const pageBox = this.commentLayerDiv.getBoundingClientRect();

    const coordinates = {
      x: (event.pageX - pageBox.left - dragAndDropData.iconCoordinates.x) / this.props.scale,
      y: (event.pageY - pageBox.top - dragAndDropData.iconCoordinates.y) / this.props.scale
    };

    const droppedAnnotation = {
      ...this.props.allAnnotations[dragAndDropData.uuid],
      ...coordinates
    };

    this.props.requestMoveAnnotation(droppedAnnotation);
  }

  mouseListener = (event) => {
    if (this.props.isPlacingAnnotation) {
      const pageCoords = getPageCoordinatesOfMouseEvent(
        event,
        this.commentLayerDiv.getBoundingClientRect(),
        this.props.scale
      );

      this.props.showPlaceAnnotationIcon(this.props.pageIndex, pageCoords);
    }
  }

  // To specify the component as droppable, we need to preventDefault on the event.
  onPageDragOver = (event) => event.preventDefault()

  getCommentLayerDivRef = (ref) => this.commentLayerDiv = ref

  getAnnotationsForPage = () => this.props.comments.concat(this.getPlacingAnnotation()).
      filter((comment) => comment.page === pageNumberOfPageIndex(this.props.pageIndex))

  getCommentIcons = () => this.getAnnotationsForPage().map((comment) => <CommentIcon
    comment={comment}
    position={{
      x: comment.x * this.props.scale,
      y: comment.y * this.props.scale
    }}
    key={keyOfAnnotation(comment)}
    onClick={comment.isPlacingAnnotationIcon ? _.noop : this.props.handleSelectCommentIcon} />)

  render() {
    return <div
      id={`comment-layer-${this.props.pageIndex}-${this.props.file}`}
      style={DIV_STYLING}
      onDragOver={this.onPageDragOver}
      onDrop={this.onCommentDrop}
      onClick={this.onPageClick}
      onMouseMove={this.mouseListener}
      ref={this.getCommentLayerDivRef}>
      {this.getCommentIcons()}
      <div
        ref={this.props.getTextLayerRef}
        className="textLayer"/>
    </div>;
  }
}

CommentLayer.propTypes = {
  comments: PropTypes.arrayOf(PropTypes.shape({
    comment: PropTypes.string,
    uuid: PropTypes.number,
    page: PropTypes.number,
    x: PropTypes.number,
    y: PropTypes.number
  })),
  getTextLayerRef: PropTypes.func,
  handleSelectCommentIcon: PropTypes.func,
  placingAnnotationIconPageCoords: PropTypes.object,
  isPlacingAnnotation: PropTypes.bool,
  scale: PropTypes.number,
  pageIndex: PropTypes.number,
  file: PropTypes.string,
  documentId: PropTypes.number
};

const mapStateToProps = (state, ownProps) => ({
  ...state.readerReducer.ui.pdf,
  ..._.pick(state.readerReducer, 'placingAnnotationIconPageCoords'),
  comments: makeGetAnnotationsByDocumentId(state.readerReducer)(ownProps.documentId),
  allAnnotations: state.readerReducer.annotations
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    placeAnnotation,
    handleSelectCommentIcon,
    requestMoveAnnotation,
    showPlaceAnnotationIcon
  }, dispatch)
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(CommentLayer);
