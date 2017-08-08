import React from 'react';
import Button from '../components/Button';
import { connect } from 'react-redux';
import * as Constants from './constants';
import _ from 'lodash';
import { makeGetAnnotationsByDocumentId } from './selectors';
import { ChevronDown, ChevronUp } from '../components/RenderFunctions';

class CommentIndicator extends React.PureComponent {
  shouldComponentUpdate = (nextProps) => !_.isEqual(this.props, nextProps)

  toggleComments = () => this.props.handleToggleCommentOpened(this.props.docId)

  render() {
    const { annotationsCount, expanded, docId } = this.props;
    const name = `expand ${annotationsCount} comments`;
    const commentArrowComponent = expanded ? <ChevronUp /> : <ChevronDown />;

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

const mapDispatchToProps = (dispatch) => ({
  handleToggleCommentOpened(docId) {
    dispatch({
      type: Constants.TOGGLE_COMMENT_LIST,
      payload: {
        docId
      }
    });
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CommentIndicator);
