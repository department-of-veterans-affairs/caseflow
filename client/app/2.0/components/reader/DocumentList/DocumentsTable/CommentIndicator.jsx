// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { ChevronDown, ChevronUp } from 'app/components/RenderFunctions';
import Button from 'app/components/Button';

/**
 * Comment Indicator Component
 * @param {Object} props -- Contains the annotation count and expanded state
 */
export const CommentIndicator = ({ comments, toggleComment, doc }) => {
  // Calculate the count of comments for this document
  const commentsCount = comments.filter((comment) => comment.document_id === doc.id).length;

  return (
    <span className="document-list-comments-indicator">
      {commentsCount > 0 &&
      <Button
        classNames={['cf-btn-link']}
        href="#"
        ariaLabel={`expand ${commentsCount} comments`}
        name={`expand ${commentsCount} comments`}
        id={`expand-${doc.id}-comments-button`}
        onClick={() => toggleComment(doc.id, doc.listComments)}
      >
        {commentsCount}
        {doc.listComments ? <ChevronUp /> : <ChevronDown />}
      </Button>
      }
    </span>
  );
};

CommentIndicator.propTypes = {
  doc: PropTypes.object,
  comments: PropTypes.array,
  expanded: PropTypes.bool,
  toggleComment: PropTypes.func
};
