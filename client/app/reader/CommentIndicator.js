import React from 'react';
import Button from '../components/Button';
import { connect } from 'react-redux';
import { getAnnotationByDocumentId } from './utils';
import * as Constants from './constants';

class CommentIndicator extends React.PureComponent {
  toggleComments = () => {
    this.props.handleToggleCommentOpened(this.props.doc.id);
  }

  render() {
    const numberOfComments = _.size(this.props.numberAnnotations);
    const icon = `fa fa-3 ${this.props.doc.listComments ?
      'fa-angle-up' : 'fa-angle-down'}`;
    const name = `expand ${numberOfComments} comments`;

    return <span className="document-list-comments-indicator">
      {numberOfComments > 0 &&
        <span>
          <Button
            classNames={['cf-btn-link']}
            href="#"
            ariaLabel={name}
            name={name}
            id={`expand-${this.props.doc.id}-comments-button`}
            onClick={this.toggleComments}>{numberOfComments}
            <i className={`document-list-comments-indicator-icon ${icon}`}/>
          </Button>
        </span>
      }
    </span>;
  }
}

const commentIndicatorMapStateToProps = (state, ownProps) => ({
  numberAnnotations: getAnnotationByDocumentId(state, ownProps.doc.id)
});
const commentIndicatorMapDispatchToProps = (dispatch) => ({
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
  commentIndicatorMapStateToProps,
  commentIndicatorMapDispatchToProps
)(CommentIndicator);
