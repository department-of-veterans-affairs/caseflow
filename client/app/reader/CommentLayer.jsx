import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import _ from 'lodash';

import { makeGetAnnotationsByDocumentId } from '../reader/selectors';
import CommentIcon from './CommentIcon';
import { keyOfAnnotation, pageNumberOfPageIndex, getPageCoordinatesOfMouseEvent } from './utils';
import { handleSelectCommentIcon } from '../reader/PdfViewer/PdfViewerActions';

import {
  placeAnnotation,
  showPlaceAnnotationIcon,
  requestMoveAnnotation,
} from '../reader/AnnotationLayer/AnnotationActions';

import { CATEGORIES } from '../reader/analytics';
import { css } from 'glamor';
import { COLORS } from '../constants/AppConstants';

const DIV_STYLING = {
  width: '100%',
  height: '100%',
  zIndex: 10,
  position: 'relative',
};

const SELECTION_STYLING = css({
  '> div': {
    '::selection': {
      background: COLORS.COLOR_COOL_BLUE_LIGHTER,
    },
    '::-moz-selection': {
      background: COLORS.COLOR_COOL_BLUE_LIGHTER,
    },
  },
});

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
      this.props.scale,
      this.props.rotation
    );

    this.props.placeAnnotation(
      pageNumberOfPageIndex(this.props.pageIndex),
      {
        xPosition: x,
        yPosition: y,
      },
      this.props.documentId
    );
  };

  getPlacingAnnotation = () => {
    if (this.props.placingAnnotationIconPageCoords && this.props.isPlacingAnnotation) {
      return [
        {
          temporaryId: 'placing-annotation-icon',
          page: pageNumberOfPageIndex(this.props.placingAnnotationIconPageCoords.pageIndex),
          isPlacingAnnotationIcon: true,
          ..._.pick(this.props.placingAnnotationIconPageCoords, 'x', 'y'),
        },
      ];
    }

    return [];
  };
  // Move the comment when it's dropped on a page
  // eslint-disable-next-line max-statements
  onCommentDrop = (event) => {
    const dragAndDropPayload = event.dataTransfer.getData('text');

    // Fix for Firefox browsers. Need to call preventDefault() so that
    // Firefox does not navigate to anything.com.
    // Issue 2969
    event.preventDefault();

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

    const coordinates = getPageCoordinatesOfMouseEvent(
      event,
      this.commentLayerDiv.getBoundingClientRect(),
      this.props.scale,
      this.props.rotation
    );

    const droppedAnnotation = {
      ...this.props.allAnnotations[dragAndDropData.uuid],
      ...coordinates,
      page: pageNumberOfPageIndex(this.props.pageIndex),
    };

    this.props.requestMoveAnnotation(droppedAnnotation);
  };

  mouseListener = (event) => {
    if (this.props.isPlacingAnnotation) {
      const pageCoords = getPageCoordinatesOfMouseEvent(
        event,
        this.commentLayerDiv.getBoundingClientRect(),
        this.props.scale,
        this.props.rotation
      );

      this.props.showPlaceAnnotationIcon(this.props.pageIndex, pageCoords);
    }
  };

  // To specify the component as droppable, we need to preventDefault on the event.
  onPageDragOver = (event) => event.preventDefault();

  getCommentLayerDivRef = (ref) => (this.commentLayerDiv = ref);

  getAnnotationsForPage = () =>
    this.props.comments.
      concat(this.getPlacingAnnotation()).
      filter((comment) => comment.page === pageNumberOfPageIndex(this.props.pageIndex));

  getCommentIcons = () =>
    this.getAnnotationsForPage().map((comment) => (
      <CommentIcon
        comment={comment}
        rotation={-this.props.rotation}
        position={{
          x: comment.x * this.props.scale,
          y: comment.y * this.props.scale,
        }}
        key={keyOfAnnotation(comment)}
        onClick={comment.isPlacingAnnotationIcon ? _.noop : this.props.handleSelectCommentIcon}
      />
    ));

  render() {
    // Instead of redrawing the text on scales, we just do a CSS transform which is faster.
    const TEXT_LAYER_STYLING = {
      width: `${this.props.dimensions.width}px`,
      height: `${this.props.dimensions.height}px`,
      transform: `scale(${this.props.scale})`,
      transformOrigin: 'left top',
      opacity: 1,
    };

    return (
      <div
        id={`comment-layer-${this.props.pageIndex}-${this.props.file}`}
        style={DIV_STYLING}
        onDragOver={this.onPageDragOver}
        onDrop={this.onCommentDrop}
        onClick={this.onPageClick}
        onMouseMove={this.mouseListener}
        ref={this.getCommentLayerDivRef}
      >
        {this.props.isVisible && this.getCommentIcons()}
        <div {...SELECTION_STYLING} style={TEXT_LAYER_STYLING} ref={this.props.getTextLayerRef} className="textLayer" />
      </div>
    );
  }
}

CommentLayer.propTypes = {
  comments: PropTypes.arrayOf(
    PropTypes.shape({
      comment: PropTypes.string,
      uuid: PropTypes.number,
      page: PropTypes.number,
      x: PropTypes.number,
      y: PropTypes.number,
    })
  ),
  dimensions: PropTypes.shape({
    width: PropTypes.number,
    height: PropTypes.number,
  }),
  isVisible: PropTypes.bool,
  getTextLayerRef: PropTypes.func,
  handleSelectCommentIcon: PropTypes.func,
  placingAnnotationIconPageCoords: PropTypes.object,
  isPlacingAnnotation: PropTypes.bool,
  scale: PropTypes.number,
  rotation: PropTypes.number,
  pageIndex: PropTypes.number,
  file: PropTypes.string,
  documentId: PropTypes.number,
  allAnnotations: PropTypes.array,
  showPlaceAnnotationIcon: PropTypes.func,
  requestMoveAnnotation: PropTypes.func,
  placeAnnotation: PropTypes.func,
};

const mapStateToProps = (state, ownProps) => ({
  ..._.pick(state.annotationLayer, 'placingAnnotationIconPageCoords'),
  comments: makeGetAnnotationsByDocumentId(state)(ownProps.documentId),
  isPlacingAnnotation: state.annotationLayer.isPlacingAnnotation,
  allAnnotations: state.annotationLayer.annotations,
  rotation: _.get(state.documents, [ownProps.documentId, 'rotation']),
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators(
    {
      placeAnnotation,
      handleSelectCommentIcon,
      requestMoveAnnotation,
      showPlaceAnnotationIcon,
    },
    dispatch
  ),
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CommentLayer);
