// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { constant } from 'lodash';

// Local Dependencies
import Table from 'app/components/Table';
import { Comment } from 'components/reader/DocumentList/CommentsTable/Comment';
import { formatCommentRows } from 'utils/reader';
import { documentHeaders } from 'components/reader/DocumentList/DocumentsTable/Columns';

/**
 * Comments Table Component
 * @param {Object} -- Props contain the documents and annotations
 */
export const CommentsTable = ({ onJumpToComment, documents, annotations, searchQuery, show, ...props }) => {
  // Calculate the rows
  const { rows } = formatCommentRows(documents, annotations, searchQuery);

  // Get the row Span for the table
  const span = documentHeaders(props).length;

  return show && (
    <div>
      <Table
        columns={[
          {
            span,
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
  documents: PropTypes.object.isRequired,
  onJumpToComment: PropTypes.func,
  annotations: PropTypes.array,
  searchQuery: PropTypes.string,
  show: PropTypes.bool
};
