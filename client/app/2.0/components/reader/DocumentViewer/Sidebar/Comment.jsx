// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import classNames from 'classnames';

// Internal Dependencies
import Button from 'app/components/Button';
import Highlight from 'app/components/Highlight';

/**
 * Jump to Comment Component
 * @param {Object} props -- Contains whether to show the button and its function
 */
export const JumpToComment = ({ show, jumpToComment, uuid }) => show && (
  <Button
    name="jumpToComment"
    id={`jumpToComment${uuid}`}
    classNames={['cf-btn-link comment-control-button horizontal']}
    onClick={jumpToComment}
  >
    Jump to section
  </Button>
);

JumpToComment.propTypes = {
  show: PropTypes.bool,
  jumpToComment: PropTypes.func,
  uuid: PropTypes.number
};

/**
 * Comment Component
 * @param {Object} props
 */
export const Comment = ({
  horizontalLayout,
  selected,
  jumpToComment,
  date,
  page,
  currentDocument,
  comment,
  handleClick,
  deleteComment,
  editComment,
  shareComment
}) => {
  // Set the Classes for the component
  const classes = classNames('comment-container', {
    'comment-container-selected': selected,
    'comment-horizontal-container': horizontalLayout
  });

  return horizontalLayout ? (
    <div className="horizontal-comment">
      <div className="comment-relevant-date">
        {date && <strong>{moment(date).format('MM/DD/YYYY')}</strong>}
      </div>
      <div className="comment-page-number">
        {currentDocument.type && (
          <span>
            <Highlight>{currentDocument.type}</Highlight>
          </span>
        )}
        <h4>Page {page}</h4>
        <strong>
          <JumpToComment uuid={comment.uuid} show={Boolean(jumpToComment)} jumpToComment={jumpToComment} />
        </strong>
      </div>
      <div
        className={classes}
        key={comment.comment.toString()}
        id={comment.id}
        onClick={handleClick}
      >
        <Highlight>
          {comment.comment}
        </Highlight>
      </div>
    </div>
  ) : (
    <div>
      <div className="comment-control-button-container">
        <h4>
          Page {page} <JumpToComment uuid={comment.id} show={Boolean(jumpToComment)} jumpToComment={jumpToComment} />
        </h4>
        <span>
          <div>
            <Button
              name={`delete-comment-${comment.id}`}
              classNames={['cf-btn-link comment-control-button']}
              onClick={() => deleteComment(comment.id)}
            >
              Delete
            </Button>
            <span className="comment-control-button-divider"> | </span>
            <Button
              name={`edit-comment-${comment.id}`}
              classNames={['cf-btn-link comment-control-button']}
              onClick={() => editComment(comment.id)}
            >
              Edit
            </Button>
            <span className="comment-control-button-divider"> | </span>
            <Button
              name={`share-comment-${comment.id}`}
              classNames={['cf-btn-link comment-control-button']}
              onClick={() => shareComment(comment.id)}
            >
              Share
            </Button>
          </div>
        </span>
      </div>
      <div className={classes} id={`comment-${comment.id}`} onClick={handleClick}>
        {date ? (
          <div>
            <strong>{moment(date).format('MM/DD/YYYY')}</strong> - {comment.comment}
          </div>
        ) : (
          comment.comment
        )}
      </div>
    </div>
  );
};

Comment.propTypes = {
  horizontalLayout: PropTypes.bool,
  selected: PropTypes.bool,
  jumpToComment: PropTypes.func,
  date: PropTypes.string,
  children: PropTypes.element,
  page: PropTypes.number,
  currentDocument: PropTypes.object,
  comment: PropTypes.object,
  handleClick: PropTypes.func,
  deleteComment: PropTypes.func,
  editComment: PropTypes.func,
  shareComment: PropTypes.func
};
