import React, { PropTypes } from 'react';
import Button from '../components/Button';

// A rounded rectangle with a user's comment inside.
// Comes with edit and delete buttons
export default class Comment extends React.Component {
  onDeleteComment = () => {
    this.props.onDeleteComment(this.props.uuid);
  }

  onClick = () => {
    this.props.onClick(this.props.uuid);
  }

  onEditComment = () => {
    this.props.onEditComment(this.props.uuid);
  }

  render() {
    let className = 'comment-container';

    if (this.props.selected) {
      className = `${className} comment-container-selected`;
    }

    return <div>
        <div className="comment-control-button-container">
          <span className="cf-right-side">
            <Button
              name="edit"
              classNames={["cf-btn-link comment-control-button"]}
              onClick={this.onEditComment}>
              Edit
            </Button>
            <span className="comment-control-button-divider">
              |
            </span>
            <Button
              name="delete"
              classNames={["cf-btn-link comment-control-button"]}
              onClick={this.onDeleteComment}>
              Delete
            </Button>
          </span>
        </div>
        <div
          className={className}
          key={this.props.children.toString()}
          id={this.props.id}
          onClick={this.onClick}>
          {this.props.children}
        </div>
      </div>;
  }
}

Comment.propTypes = {
  children: React.PropTypes.string,
  id: PropTypes.string,
  selected: PropTypes.bool,
  onEditComment: PropTypes.func,
  onDeleteComment: PropTypes.func,
  onClick: PropTypes.func,
  uuid: PropTypes.number
};
