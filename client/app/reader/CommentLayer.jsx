import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { makeGetAnnotationsByDocumentId } from '../reader/selectors';
import CommentIcon from '../components/CommentIcon';
import { keyOfAnnotation, pageNumberOfPageIndex, getPageCoordinatesOfMouseEvent,
  isUserEditingText } from './utils';
import _ from 'lodash';
import { handleSelectCommentIcon, placeAnnotation,
  requestMoveAnnotation, startPlacingAnnotation,
  stopPlacingAnnotation, showPlaceAnnotationIcon, } from '../reader/actions';
import { bindActionCreators } from 'redux';
import { CATEGORIES, INTERACTION_TYPES } from '../reader/analytics';

const DIV_STYLING = {
  width: '100%',
  height: '100%',
  zIndex: 10,
  position: 'relative'
};

// The comment layer is a div on top of a page that draws the comment
// icons on the page. It is also the div that receives the onClick
// events when placing new comments.
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

  componentDidMount() {
    window.addEventListener('keydown', this.keyListener);
  }

  componentWillUnmount() {
    window.removeEventListener('keydown', this.keyListener);
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
  onPageDragOver = (event) => {event.preventDefault()}

  getCommentLayerDivRef = (ref) => this.commentLayerDiv = ref

  getAnnotationsForPage = () => {
    return this.props.comments.concat(this.getPlacingAnnotation()).
      filter((comment) => comment.page === pageNumberOfPageIndex(this.props.pageIndex));
  }

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
      id={`comment-layer-${this.props.pageIndex}`}
      style={DIV_STYLING}
      onDragOver={this.onPageDragOver}
      onDrop={this.onCommentDrop}
      onClick={this.onPageClick}
      onMouseMove={this.mouseListener}
      ref={this.getCommentLayerDivRef}>
      {this.getCommentIcons()}
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
  handleSelectCommentIcon: PropTypes.func,
  placingAnnotationIconPageCoords: PropTypes.object,
  isPlacingAnnotation: PropTypes.bool,
  scale: PropTypes.number,
  pageIndex: PropTypes.number,
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
    startPlacingAnnotation,
    stopPlacingAnnotation,
    showPlaceAnnotationIcon
  }, dispatch)
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(CommentLayer);
