import React from 'react';
import Button from '../components/Button';
import { connect } from 'react-redux';
import * as Constants from './constants';
import _ from 'lodash';

class CommentIndicator extends React.PureComponent {
  toggleComments = () => {
    this.props.handleToggleCommentOpened(this.props.doc.id);
  }

  getRenderArgs() {
    return {
     annotationCount: _.size(this.props.annotationsPerDocument[doc.id])} expanded={doc.listComments} 

    }
  }

  render() {
    const { annotationCount } = this.props;
    const icon = `fa fa-3 ${this.props.expanded ?
      'fa-angle-up' : 'fa-angle-down'}`;
    const name = `expand ${annotationCount} comments`;

    return <span className="document-list-comments-indicator">
      {annotationCount > 0 &&
        <span>
          <Button
            classNames={['cf-btn-link']}
            href="#"
            ariaLabel={name}
            name={name}
            id={`expand-${this.props.doc.id}-comments-button`}
            onClick={this.toggleComments}>{annotationCount}
            <i className={`document-list-comments-indicator-icon ${icon}`}/>
          </Button>
        </span>
      }
    </span>;
  }
}

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
  null,
  mapDispatchToProps
)(CommentIndicator);
