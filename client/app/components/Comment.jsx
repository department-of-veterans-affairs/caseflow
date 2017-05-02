import React, { PropTypes } from 'react';
import Button from '../components/Button';
import _ from 'lodash';

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

  getControlButtons = () => {
    if (!(this.props.onEditComment && this.props.onDeleteComment)) {
      return;
    }

    return <div>
        <Button
          name="delete"
          classNames={['cf-btn-link comment-control-button']}
          onClick={this.onDeleteComment}>
          Delete
        </Button>
        <span className="comment-control-button-divider">
          |
        </span>
        <Button
          name="edit"
          classNames={['cf-btn-link comment-control-button']}
          onClick={this.onEditComment}>
          Edit
        </Button>
      </div>;
  }

  render() {
    let className = 'comment-container';

    if (this.props.selected) {
      className = `${className} comment-container-selected`;
    }

    let jumpToSectionButton = null;

    if (this.props.onJumpToComment) {
      jumpToSectionButton = <Button
          name="jumpToComment"
          classNames={['cf-btn-link comment-control-button']}
          onClick={this.props.onJumpToComment}>
          Jump to section
        </Button>;
    }

    let commentToRender = <div>
        <div className="comment-control-button-container">
          <h4>Page {this.props.page} {jumpToSectionButton}</h4>
          <span>
            {this.getControlButtons()}
          </span>
        </div>
        <div
          className={className}
          id={this.props.id}
          onClick={this.onClick}>
          {this.props.children}
        </div>
      </div>;

    if (this.props.horizontalLayout) {
      className = `${className} comment-horizontal-container`;
      commentToRender = <div className="horizontal-comment">
        <div className="comment-page-number">
          <h4>Page {this.props.page}</h4>
        </div>
        <div className="comment-jump-to-section">
          <strong>{jumpToSectionButton}</strong>
        </div>
        <div
          className={`${className} comment-content`}
          key={this.props.children.toString()}
          id={this.props.id}
          onClick={this.onClick}>
          {this.props.children}
        </div>
      </div>;
    }

    return commentToRender;
  }
}

Comment.defaultProps = {
  onClick: _.noop
};

Comment.propTypes = {
  children: React.PropTypes.string,
  id: PropTypes.string,
  selected: PropTypes.bool,
  onEditComment: PropTypes.func,
  onDeleteComment: PropTypes.func,
  onJumpToComment: PropTypes.func,
  onClick: PropTypes.func,
  page: PropTypes.number,
  uuid: PropTypes.number,
  horizontalLayout: PropTypes.bool
};
