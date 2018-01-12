import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { connect } from 'react-redux';

import { getAnnotationsPerDocument } from './selectors';
import Comment from './Comment';
import Table from '../components/Table';

class CommentsTable extends React.PureComponent {
  getTbodyRef = (elem) => this.tbodyElem = elem;

  getRowObjects = () => {
    return _(this.props.annotationsPerDocument).
      map((notes) => notes.map((note) => {
        const docType = this.props.documents.filter((doc) => doc.id === note.documentId)[0].type;

        return _.extend({}, note, { docType });
      })).
      flatten().
      sortBy((note) => note.relevant_date || note.receipt_date).
      value();
  };

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

  render() {
    return <div>
      <Table
        columns={this.getCommentColumn}
        rowObjects={this.getRowObjects()}
        className="documents-table full-width"
        bodyClassName="cf-document-list-body"
        tbodyRef={this.getTbodyRef}
        getKeyForRow={(index) => index}
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
  annotationsPerDocument: getAnnotationsPerDocument(state)
});

export default connect(mapStateToProps)(CommentsTable);
