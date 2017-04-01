import React, { PropTypes } from 'react';
import { commentIcon } from './RenderFunctions';

export default class CommentIcon extends React.Component {
  onClick = () => {
    this.props.onClick(this.props.uuid);
  }

  onDragStart = (event) => {
    this.props.onDragStart(this.props.uuid, this.props.page, event);
  }

  render = () => {
    return <div
      style={{
        left: this.props.x,
        top: this.props.y
      }}
      className="commentIcon-container"
      onClick={this.onClick}
      draggable={this.props.onIconMoved !== null}
      onDragStart={this.onDragStart}
      onDrag={this.props.onDrag} >
        {commentIcon(this.props.selected)}
      </div>;
  }
}

// CommentIcon.defaultProps = {
// };

CommentIcon.propTypes = {
  selected: PropTypes.bool,
  onClick: PropTypes.func,
  onIconMoved: PropTypes.func,
  xPosition: PropTypes.number,
  yPosition: PropTypes.number,
  uuid: PropTypes.number,
  page: PropTypes.number
};
