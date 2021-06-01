// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { noop } from 'lodash';

// Local Dependencies
import Highlight from 'app/components/Highlight';
import { commentsClass } from 'styles/reader/DocumentList/CommentsTable';
import { useDispatch } from 'react-redux';
import { ControlButtons } from 'components/reader/DocumentList/CommentsTable/ControlButtons';
import { JumpButton } from 'components/reader/DocumentList/CommentsTable/JumpButton';
import { DateLabel } from 'components/shared/DateLabel';

/**
 * Comment Component
 * @param {Object} props -- Props contain the comment details
 */
export const Comment = ({
  uuid,
  horizontalLayout,
  date,
  docType,
  onJumpToComment,
  onClick,
  id,
  children,
  selected,
  page,
}) => {
  // Create the Dispatcher
  const dispatch = useDispatch();

  return horizontalLayout ? (
    <div className="horizontal-comment">
      <DateLabel date={date} />
      <div className="comment-page-number">
        {docType && <span> <Highlight>{docType}</Highlight> </span>}
        <h4>Page {page}</h4>
        {onJumpToComment && <strong><JumpButton jumpToComment={onJumpToComment} uuid={uuid} /></strong>}
      </div>
      <div
        className={commentsClass(selected, horizontalLayout)}
        key={children.toString()}
        id={id}
        onClick={() => dispatch(onClick())}>
        <Highlight>
          {children}
        </Highlight>
      </div>
    </div>
  ) : (
    <div>
      <div className="comment-control-button-container">
        <h4>
          Page {page} {onJumpToComment && (<JumpButton jumpToComment={onJumpToComment} uuid={uuid} />)}
        </h4>
        <span>
          <ControlButtons />
        </span>
      </div>
      <div
        className={commentsClass(selected, horizontalLayout)}
        id={id}
        onClick={() => dispatch(onClick())}>
      >
        {date ? <div><strong>{moment(date).format('MM/DD/YYYY')}</strong> - {children}</div> : children}
      </div>
    </div>
  );
};

Comment.defaultProps = {
  onClick: noop
};

Comment.propTypes = {
  children: PropTypes.string,
  date: PropTypes.string,
  docType: PropTypes.string,
  id: PropTypes.string,
  selected: PropTypes.bool,
  onEditComment: PropTypes.func,
  openAnnotationDeleteModal: PropTypes.func,
  openAnnotationShareModal: PropTypes.func,
  onJumpToComment: PropTypes.func,
  onClick: PropTypes.func,
  page: PropTypes.number,
  uuid: PropTypes.number,
  horizontalLayout: PropTypes.bool
};

