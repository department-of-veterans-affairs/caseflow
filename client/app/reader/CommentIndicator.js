import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import { makeGetAnnotationsByDocumentId } from './selectors';
import { ChevronDownIcon } from '../components/icons/ChevronDownIcon';
import { ChevronUpIcon } from '../components/icons/ChevronUpIcon';
import Button from '../components/Button';
import { handleToggleCommentOpened } from '../reader/Documents/DocumentsActions';

class CommentIndicator extends React.Component {
  shouldComponentUpdate = (nextProps) => !_.isEqual(this.props, nextProps)

  toggleComments = () => this.props.handleToggleCommentOpened(this.props.docId, this.props.expanded)

  render() {
    const { annotationsCount, expanded, docId } = this.props;
    const name = `expand ${annotationsCount} comments`;
    const commentArrowComponent = expanded ? <ChevronUpIcon /> : <ChevronDownIcon />;

    return <span className="document-list-comments-indicator">
      {annotationsCount > 0 &&
        <Button
          classNames={['cf-btn-link']}
          href="#"
          ariaLabel={name}
          name={name}
          id={`expand-${docId}-comments-button`}
          onClick={this.toggleComments}>
          {annotationsCount}
          {commentArrowComponent}
        </Button>
      }
    </span>;
  }
}

const mapStateToProps = (state, ownProps) => {
  const doc = state.documents[ownProps.docId];

  return {
    docId: doc.id,
    expanded: doc.listComments,
    annotationsCount: _.size(makeGetAnnotationsByDocumentId(state)(ownProps.docId))
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    handleToggleCommentOpened
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CommentIndicator);
