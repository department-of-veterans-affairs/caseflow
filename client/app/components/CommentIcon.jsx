import React, { PropTypes } from 'react';
import { commentIcon } from './RenderFunctions';

export default class CommentIcon extends React.Component {
  render() {
    return <div style={{ left: this.props.x, top: this.props.y }} className="commentIcon-container">
        {commentIcon()}
      </div>;
  }
}

// CommentIcon.defaultProps = {
// };

CommentIcon.propTypes = {
  x: PropTypes.number,
  y: PropTypes.number
};
