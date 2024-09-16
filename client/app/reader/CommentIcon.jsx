import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import { ReaderCommentIcon } from '../components/icons/ReaderCommentIcon';

export class CommentIcon extends React.Component {
  onClick = () => {
    this.props.onClick(this.props.comment);
  };

  onDragStart = (event) => {
    const dragAndDropData = {
      uuid: this.props.comment.uuid,
      iconCoordinates: {
        x: event.pageX - event.target.getBoundingClientRect().left,
        y: event.pageY - event.target.getBoundingClientRect().top,
      },
    };

    // The dataTransfer object is an HTML5 Drag and Drop concept. It allows us
    // to communicate directly with whatever method will receive our drop.
    event.dataTransfer.setData('text', JSON.stringify(dragAndDropData));
  };

  render() {
    const selected = this.props.comment.id === this.props.selectedAnnotationId;

    return (
      <div
        ref={this.props.innerRef}
        style={{
          left: this.props.position.x,
          top: this.props.position.y,
          transform: `rotate(${this.props.rotation}deg)`,
          pointerEvents: 'auto',
        }}
        data-placing-annotation-icon={this.props.comment.isPlacingAnnotationIcon}
        className="commentIcon-container"
        id={`commentIcon-container-${this.props.comment.uuid}`}
        onClick={this.onClick}
        draggable={this.props.onDrag !== null}
        onDragStart={this.onDragStart}
      >
        <ReaderCommentIcon selected={selected} id={this.props.comment.uuid} />
      </div>
    );
  }
}

CommentIcon.propTypes = {
  comment: PropTypes.object.isRequired,
  onClick: PropTypes.func.isRequired,
  position: PropTypes.shape({
    x: PropTypes.number,
    y: PropTypes.number,
  }),
  rotation: PropTypes.number,
  selectedAnnotationId: PropTypes.number,
  onDrag: PropTypes.any,
  innerRef: PropTypes.any,
};

const mapStateToProps = (state) => ({
  ..._.pick(state.annotationLayer, 'selectedAnnotationId'),
});

export default connect(
  mapStateToProps,
  null,
  null,
  { forwardRef: true }
)(CommentIcon);
