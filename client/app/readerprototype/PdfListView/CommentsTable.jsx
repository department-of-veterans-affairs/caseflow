import React from 'react';
import PropTypes from 'prop-types';
import { escapeRegExp, constant, flatten, groupBy, pick, sortBy, map, filter } from 'lodash';
import { connect } from 'react-redux';

import { getAnnotationsPerDocument } from './selectors';
import Comment from './Comment';
import Table from '../components/Table';

export const getRowObjects = (documents, annotationsPerDocument, searchQuery = '') => {
  const groupedAnnotations = groupBy(flatten(map(annotationsPerDocument, (notes) =>
    notes.map((note) => {
      // eslint-disable-next-line camelcase
      const { type, serialized_receipt_date } = filter(documents, (doc) => doc.id === note.documentId)[0];

      return {
        ...note,
        docType: type,
        serialized_receipt_date
      };
    })
  )).
    filter((note) => {
      if (!searchQuery) {
        return true;
      }

      const query = new RegExp(escapeRegExp(searchQuery), 'i');

      return note.comment.match(query) || note.docType.match(query);
    }),
  (note) => (note.relevant_date ? 'relevant_date' : 'serialized_receipt_date'));

  // groupBy returns { relevant_date: [notes w/relevant_date], serialized_receipt_date: [notes w/out] }
  return sortBy(groupedAnnotations.relevant_date, 'relevant_date').concat(
    sortBy(groupedAnnotations.serialized_receipt_date, 'serialized_receipt_date')
  );
};

class CommentsTable extends React.PureComponent {
  getCommentColumn = () => [
    {
      header: 'Sorted by relevant date',
      valueFunction: (comment, idx) => (
        <Comment
          key={comment.uuid}
          id={`comment-${idx}`}
          page={comment.page}
          onJumpToComment={this.props.onJumpToComment(comment)}
          uuid={comment.uuid}
          date={comment.relevant_date}
          docType={comment.docType}
          horizontalLayout
        >
          {comment.comment}
        </Comment>
      )
    }
  ];

  getKeyForRow = (rowNumber, object) => object.uuid;

  render() {
    const { documents, annotationsPerDocument, searchQuery } = this.props;

    return (
      <div>
        <Table
          columns={this.getCommentColumn}
          rowObjects={getRowObjects(documents, annotationsPerDocument, searchQuery)}
          className="documents-table full-width"
          bodyClassName="cf-document-list-body"
          getKeyForRow={this.getKeyForRow}
          headerClassName="comments-table-header"
          rowClassNames={constant('borderless')}
        />
      </div>
    );
  }
}

CommentsTable.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func.isRequired,
  annotationsPerDocument: PropTypes.array,
  searchQuery: PropTypes.string
};

const mapStateToProps = (state) => ({
  annotationsPerDocument: getAnnotationsPerDocument(state),
  ...pick(state.documentList.docFilterCriteria, 'searchQuery')
});

export default connect(mapStateToProps)(CommentsTable);
