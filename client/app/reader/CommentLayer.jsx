import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { makeGetAnnotationsByDocumentId } from '../reader/selectors';
import CommentIcon from '../components/CommentIcon';
import { keyOfAnnotation, pageNumberOfPageIndex, getPageCoordinatesOfMouseEvent } from './utils';
import _ from 'lodash';
import { handleSelectCommentIcon, placeAnnotation } from '../reader/actions';
import { bindActionCreators } from 'redux';

const DIV_STYLING = {
  width: '100%',
  height: '100%'
};

class CommentLayer extends PureComponent {
  constructor(props) {
    super(props);

    this.commentLayer = null;
  }

  onPageClick = (event) => {
    if (!this.props.isPlacingAnnotation) {
      return;
    }

    const { x, y } = getPageCoordinatesOfMouseEvent(
      event,
      this.commentLayer.getBoundingClientRect(),
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

  getCommentLayerRef = (ref) => this.commentLayer = ref

  getAnnotationsForPage = () => {
    const placingAnnotation = this.props.placingAnnotationIconPageCoords && this.props.isPlacingAnnotation ?
    [{
      temporaryId: 'placing-annotation-icon',
      page: pageNumberOfPageIndex(this.props.placingAnnotationIconPageCoords.pageIndex),
      isPlacingAnnotationIcon: true,
      ..._.pick(this.props.placingAnnotationIconPageCoords, 'x', 'y')
    }] : [];

    return this.props.comments.concat(placingAnnotation).
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
      onClick={this.onPageClick}
      ref={this.getCommentLayerRef}>
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
  ...state.ui.pdf,
  ..._.pick(state, 'placingAnnotationIconPageCoords'),
  comments: makeGetAnnotationsByDocumentId(state)(ownProps.documentId)
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    placeAnnotation,
    handleSelectCommentIcon
  }, dispatch)
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(CommentLayer);
