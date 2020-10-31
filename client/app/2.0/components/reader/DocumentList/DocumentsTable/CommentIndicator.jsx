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
export const CommentIndicator = ({ annotationsCount, expanded, docId, toggleComment }) => (
  <span className="document-list-comments-indicator">
    {annotationsCount > 0 &&
      <Button
        classNames={['cf-btn-link']}
        href="#"
        ariaLabel={`expand ${annotationsCount} comments`}
        name={`expand ${annotationsCount} comments`}
        id={`expand-${docId}-comments-button`}
        onClick={() => toggleComment(docId, expanded)}
      >
        {annotationsCount}
        {expanded ? <ChevronUp /> : <ChevronDown />}
      </Button>
    }
  </span>
);

CommentIndicator.propTypes = {
  annotationsCount: PropTypes.number,
  expanded: PropTypes.bool,
  docId: PropTypes.string,
  toggleComment: PropTypes.func
};
