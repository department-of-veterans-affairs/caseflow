// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { constant } from 'lodash';

// Local Dependencies
import Table from 'app/components/Table';
import Comment from 'components/reader/DocumentList/CommentsTable/Comment';
import { formatCommentRows } from 'utils/reader/format';

/**
 * Comments Table Component
 * @param {Object} -- Props contain the documents and annotations
 */
export const CommentsTable = ({ onJumpToComment, documents, annotationsPerDocument, searchQuery }) => {
  // Calculate the rows
  const { rows } = formatCommentRows(documents, annotationsPerDocument, searchQuery);

  return (
    <div>
      <Table
        columns={[
          {
            header: 'Sorted by relevant date',
            valueFunction: (comment, idx) => (
              <Comment
                key={comment.uuid}
                id={`comment-${idx}`}
                page={comment.page}
                onJumpToComment={() => onJumpToComment(comment)}
                uuid={comment.uuid}
                date={comment.relevant_date}
                docType={comment.docType}
                horizontalLayout
              >
                {comment.comment}
              </Comment>
            )
          }
        ]}
        rowObjects={rows}
        className="documents-table full-width"
        bodyClassName="cf-document-list-body"
        getKeyForRow={(_, row) => row.uuid}
        headerClassName="comments-table-header"
        rowClassNames={constant('borderless')}
      />
    </div>
  );
};

CommentsTable.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func.isRequired,
  annotationsPerDocument: PropTypes.array,
  searchQuery: PropTypes.string
};
