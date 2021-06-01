// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import classNames from 'classnames';

// Internal Dependencies
import Button from 'app/components/Button';
import { Highlight } from 'components/reader/DocumentList/Highlight';
import { Link } from 'react-router-dom';
import { DateLabel } from 'components/shared/DateLabel';

/**
 * Jump to Comment Component
 * @param {Object} props -- Contains whether to show the button and its function
 */
export const JumpToComment = ({ documentPathBase, currentDocument, comment, selectComment }) => (
  <Link
    onClick={() => selectComment(comment)}
    className={classNames('cf-btn-link', { 'comment-control-button': true, horizontal: true })}
    to={`${documentPathBase}/${currentDocument.id}`}
  >
    Jump to section
  </Link>
);

JumpToComment.propTypes = {
  selectComment: PropTypes.func,
  documentPathBase: PropTypes.string,
  currentDocument: PropTypes.object,
  comment: PropTypes.object,
  showPdf: PropTypes.func,
};

/**
 * Comment Component
 * @param {Object} props
 */
export const Comment = ({
  horizontalLayout,
  selected,
  date,
  page,
  comment,
  handleClick,
  deleteComment,
  editComment,
  shareComment,
  filterCriteria,
  ...props
}) => {
  // Set the Classes for the component
  const classes = classNames('comment-container', {
    'comment-container-selected': selected,
    'comment-horizontal-container': horizontalLayout
  });

  return horizontalLayout ? (
    <div className="horizontal-comment">
      <DateLabel date={date} />
      <div className="comment-page-number">
        {comment.docType && (
          <span>
            <Highlight searchQuery={filterCriteria?.searchQuery}>
              {comment.docType}
            </Highlight>
          </span>
        )}
        <h4>Page {page}</h4>
        <JumpToComment comment={comment} {...props} />
      </div>
      <div
        className={classes}
        key={comment.comment.toString()}
        id={comment.id}
        onClick={handleClick}
      >
        <Highlight searchQuery={filterCriteria?.searchQuery}>
          {comment.comment}
        </Highlight>
      </div>
    </div>
  ) : (
    <div>
      <div className="comment-control-button-container">
        <h4>
          Page {page}
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
  filterCriteria: PropTypes.object,
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
