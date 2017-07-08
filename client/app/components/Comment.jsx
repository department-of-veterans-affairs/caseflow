import React from 'react';
import PropTypes from 'prop-types';

import Button from '../components/Button';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { openAnnotationDeleteModal } from '../reader/actions';
import Highlight from '../components/Highlight';

// A rounded rectangle with a user's comment inside.
// Comes with edit and delete buttons
export class Comment extends React.Component {
  onClick = () => {
    this.props.onClick(this.props.uuid);
  }

  onEditComment = () => this.props.onEditComment(this.props.uuid)

  onClickDelete = () => this.props.openAnnotationDeleteModal(this.props.uuid)

  getControlButtons = () => {
    return <div>
        <Button
          name={`delete-comment-${this.props.uuid}`}
          classNames={['cf-btn-link comment-control-button']}
          onClick={this.onClickDelete}>
          Delete
        </Button>
        <span className="comment-control-button-divider">
          |
        </span>
        <Button
          name={`edit-comment-${this.props.uuid}`}
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
          id={`jumpToComment${this.props.uuid}`}
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
          <Highlight>
            {this.props.children}
          </Highlight>
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
  children: PropTypes.string,
  id: PropTypes.string,
  selected: PropTypes.bool,
  onEditComment: PropTypes.func,
  openAnnotationDeleteModal: PropTypes.func,
  onJumpToComment: PropTypes.func,
  onClick: PropTypes.func,
  page: PropTypes.number,
  uuid: PropTypes.number,
  horizontalLayout: PropTypes.bool
};

const mapStateToProps = null;
const mapDispatchToProps = (dispatch) => bindActionCreators({ openAnnotationDeleteModal }, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(Comment);

