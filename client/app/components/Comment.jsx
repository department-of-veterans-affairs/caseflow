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
    let className = 'cf-pdf-comment-list-item';

    if (this.props.selected) {
      className = `${className} cf-comment-selected`;
    }

    let editButtons = [];

    if (this.props.onEditComment) {
      editButtons.push(<Button
        name="edit"
        classNames={["cf-btn-link comment-control-button"]}
        onClick={this.onEditComment}>
        Edit
      </Button>);
      if (this.props.onDeleteComment) {
        editButtons.push(<span className="comment-control-button-divider">
            |
          </span>);
      }
    }
    if (this.props.onDeleteComment) {
     editButtons.push(<Button
        name="delete"
        classNames={["cf-btn-link comment-control-button"]}
        onClick={this.onDeleteComment}>
        Delete
      </Button>);
    }

    let jumpToSectionButton = null;

    if (this.props.onJumpToComment) {
      jumpToSectionButton = <Button
          name="jumpToComment"
          classNames={["cf-btn-link comment-control-button"]}
          onClick={this.props.onJumpToComment}>
          Jump to Section
        </Button>;
    }

    return <div>
        <div className="comment-control-button-container">
          <span className="cf-left-side">
            Pg. {this.props.page} {jumpToSectionButton}
          </span>
          <span>
            <span className="cf-right-side">
              {editButtons}
            </span>
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

Comment.defaultProps = {
  onClick: () => {}
}

Comment.propTypes = {
  children: React.PropTypes.string,
  id: PropTypes.string,
  selected: PropTypes.bool,
  onEditComment: PropTypes.func,
  onDeleteComment: PropTypes.func,
  onJumpToComment: PropTypes.func,
  onClick: PropTypes.func,
  page: PropTypes.number,
  uuid: PropTypes.number
};
