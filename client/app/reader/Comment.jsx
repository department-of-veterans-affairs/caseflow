import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import classNames from 'classnames';

import Button from '../components/Button';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { openAnnotationDeleteModal, openAnnotationShareModal } from '../reader/AnnotationLayer/AnnotationActions';
import { INTERACTION_TYPES } from '../reader/analytics';
import Highlight from '../components/Highlight';

// A rounded rectangle with a user's comment inside.
// Comes with edit and delete buttons
export class Comment extends React.Component {
  onClick = () => {
    this.props.onClick(this.props.uuid);
  };

  onEditComment = () => this.props.onEditComment(this.props.uuid);

  onClickDelete = () => this.props.openAnnotationDeleteModal(this.props.uuid, INTERACTION_TYPES.VISIBLE_UI);

  onShareComment = () => this.props.openAnnotationShareModal(this.props.uuid, INTERACTION_TYPES.VISIBLE_UI);

  getControlButtons = () => {
    return (
      <div>
        <Button
          name={`delete-comment-${this.props.uuid}`}
          classNames={['cf-btn-link comment-control-button']}
          onClick={this.onClickDelete}
        >
          Delete
        </Button>
        <span className="comment-control-button-divider">|</span>
        <Button
          name={`edit-comment-${this.props.uuid}`}
          classNames={['cf-btn-link comment-control-button']}
          onClick={this.onEditComment}
        >
          Edit
        </Button>
        <span className="comment-control-button-divider">|</span>
        <Button
          name={`share-comment-${this.props.uuid}`}
          classNames={['cf-btn-link comment-control-button']}
          onClick={this.onShareComment}
        >
          Share
        </Button>
      </div>
    );
  };

  render() {
    const className = classNames('comment-container', {
      'comment-container-selected': this.props.selected,
      'comment-horizontal-container': this.props.horizontalLayout,
    });
    let jumpToSectionButton = null;

    if (this.props.onJumpToComment) {
      jumpToSectionButton = (
        <Button
          name="jumpToComment"
          id={`jumpToComment${this.props.uuid}`}
          classNames={['cf-btn-link comment-control-button horizontal']}
          onClick={this.props.onJumpToComment}
        >
          Jump to section
        </Button>
      );
    }

    let textToRender = this.props.children;

    if (this.props.date) {
      textToRender = (
        <div>
          <strong>{moment(this.props.date).format('MM/DD/YYYY')}</strong> - {textToRender}
        </div>
      );
    }

    let commentToRender = (
      <div ref={this.props.innerRef}>
        <div className="comment-control-button-container">
          <h4>
            Page {this.props.page} {jumpToSectionButton}
          </h4>
          <span>{this.getControlButtons()}</span>
        </div>
        <div className={className} id={this.props.id} onClick={this.onClick}>
          {textToRender}
        </div>
      </div>
    );

    if (this.props.horizontalLayout) {
      commentToRender = (
        <div className="horizontal-comment">
          <div className="comment-relevant-date">
            {this.props.date && <strong>{moment(this.props.date).format('MM/DD/YYYY')}</strong>}
          </div>
          <div className="comment-page-number">
            {this.props.docType && (
              <span>
                <Highlight>{this.props.docType}</Highlight>
              </span>
            )}
            <h4>Page {this.props.page}</h4>
            <strong>{jumpToSectionButton}</strong>
          </div>
          <div className={className} key={this.props.children.toString()} id={this.props.id} onClick={this.onClick}>
            <Highlight>{this.props.children}</Highlight>
          </div>
        </div>
      );
    }

    return commentToRender;
  }
}

Comment.defaultProps = {
  onClick: _.noop,
};

Comment.propTypes = {
  children: PropTypes.string,
  id: PropTypes.string,
  selected: PropTypes.bool,
  onEditComment: PropTypes.func,
  openAnnotationDeleteModal: PropTypes.func,
  openAnnotationShareModal: PropTypes.func,
  onJumpToComment: PropTypes.func,
  onClick: PropTypes.func,
  page: PropTypes.number,
  uuid: PropTypes.number,
  horizontalLayout: PropTypes.bool,
  innerRef: PropTypes.any,
  date: PropTypes.number,
  docType: PropTypes.string
};

const mapStateToProps = null;
const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      openAnnotationDeleteModal,
      openAnnotationShareModal,
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Comment);
