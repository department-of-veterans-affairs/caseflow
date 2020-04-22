import React from 'react';
import PropTypes from 'prop-types';
import _, {escapeRegExp} from 'lodash';
import { connect } from 'react-redux';

import { getAnnotationsPerDocument } from './selectors';
import Comment from './Comment';
import Table from '../components/Table';

export const getRowObjects = (documents, annotationsPerDocument, searchQuery = '') => {
  const groupedAnnotations = _(annotationsPerDocument).
    map((notes) =>
      notes.map((note) => {
        const { type, serialized_receipt_date } = documents.filter((doc) => doc.id === note.documentId)[0];

        return _.extend({}, note, {
          docType: type,
          serialized_receipt_date
        });
      })).
    flatten().
    filter((note) => {
      if (!searchQuery) {
        return true;
      }

      const query = new RegExp(escapeRegExp(searchQuery), 'i');

      return note.comment.match(query) || note.docType.match(query);
    }).
    groupBy((note) => note.relevant_date ? 'relevant_date' : 'serialized_receipt_date').
    value();

  // groupBy returns { relevant_date: [notes w/relevant_date], serialized_receipt_date: [notes w/out] }
  return _.sortBy(groupedAnnotations.relevant_date, 'relevant_date').
    concat(_.sortBy(groupedAnnotations.serialized_receipt_date, 'serialized_receipt_date'));
};

class CommentsTable extends React.PureComponent {
  getCommentColumn = () => [{
    header: 'Sorted by relevant date',
    valueFunction: (comment, idx) => <Comment
      key={comment.uuid}
      id={`comment-${idx}`}
      page={comment.page}
      onJumpToComment={this.props.onJumpToComment(comment)}
      uuid={comment.uuid}
      date={comment.relevant_date}
      docType={comment.docType}
      horizontalLayout>
      {comment.comment}
    </Comment>
  }];

  getKeyForRow = (rowNumber, object) => object.uuid;

  render() {
    const {
      documents,
      annotationsPerDocument,
      searchQuery
    } = this.props;

    return <div>
      <Table
        columns={this.getCommentColumn}
        rowObjects={getRowObjects(documents, annotationsPerDocument, searchQuery)}
        className="documents-table full-width"
        bodyClassName="cf-document-list-body"
        getKeyForRow={this.getKeyForRow}
        headerClassName="comments-table-header"
        rowClassNames={_.constant('borderless')}
      />
    </div>;
  }
}

CommentsTable.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func.isRequired
};

const mapStateToProps = (state) => ({
  annotationsPerDocument: getAnnotationsPerDocument(state),
  ..._.pick(state.documentList.docFilterCriteria, 'searchQuery')
});

export default connect(mapStateToProps)(CommentsTable);
