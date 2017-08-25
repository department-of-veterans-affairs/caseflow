import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { makeGetAnnotationsByDocumentId } from '../reader/selectors';
import CommentIcon from '../components/CommentIcon';
import { keyOfAnnotation } from '../reader/utils';
import _ from 'lodash';
import { handleSelectCommentIcon } from '../reader/actions';

class CommentLayer extends PureComponent {
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

    return <span>{commentIcons[this.props.pageIndex+1]}</span>
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
  handleSelectCommentIcon: PropTypes.func
};

const mapStateToProps = (state, ownProps) => ({
  ...state.ui.pdf,
  ..._.pick(state, 'placingAnnotationIconPageCoords'),
  comments: makeGetAnnotationsByDocumentId(state)(ownProps.documentId)
});

const mapDispatchToProps = (dispatch) => ({
  handleSelectCommentIcon: (comment) => dispatch(handleSelectCommentIcon(comment))
});


export default connect(
  mapStateToProps, mapDispatchToProps
)(CommentLayer);
