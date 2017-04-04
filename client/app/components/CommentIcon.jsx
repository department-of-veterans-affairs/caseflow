import React, { PropTypes } from 'react';
import { commentIcon } from './RenderFunctions';

export default class CommentIcon extends React.Component {
  onClick = () => {
    this.props.onClick(this.props.uuid);
  }

  onDragStart = (event) => {
    event.dataTransfer.setData('text/plain', 'Random Text');
    this.props.onDragStart(this.props.uuid, this.props.page, event);
  }

  render = () => {
    return <div
      style={{
        left: this.props.position.x,
        top: this.props.position.y
      }}
      className="commentIcon-container"
      onClick={this.onClick}
      draggable={this.props.onDrag !== null}
      onDragStart={this.onDragStart} >
        {commentIcon(this.props.selected)}
      </div>;
  }
}

// CommentIcon.defaultProps = {
// };

CommentIcon.propTypes = {
  selected: PropTypes.bool,
  onClick: PropTypes.func,
  onDragStart: PropTypes.func,
  position: PropTypes.shape({
    x: PropTypes.number,
    y: PropTypes.number
  }),
  uuid: PropTypes.number,
  page: PropTypes.number
};
