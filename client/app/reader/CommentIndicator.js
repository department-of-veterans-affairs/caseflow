import React from 'react';
import Button from '../components/Button';
import { connect } from 'react-redux';
import * as Constants from './constants';
import _ from 'lodash';
import classnames from 'classnames';

const getRenderArgs = (props) =>
  ({
    annotationCount: _.size(props.annotationsPerDocument[props.doc.id]),
    expanded: props.doc.listComments,
    docId: props.doc.id
  });

class CommentIndicator extends React.PureComponent {
  shouldComponentUpdate = (nextProps) => !_.isEqual(getRenderArgs(this.props), getRenderArgs(nextProps))

  toggleComments = () => {
    this.props.handleToggleCommentOpened(this.props.doc.id);
  }

  render() {
    const { annotationCount, expanded, docId } = getRenderArgs(this.props);
    const iconClassNames = classnames('fa fa-3 document-list-comments-indicator-icon', {
      'fa-angle-up': expanded,
      'fa-angle-down': !expanded
    });
    const name = `expand ${annotationCount} comments`;

    return <span className="document-list-comments-indicator">
      {annotationCount > 0 &&
        <span>
          <Button
            classNames={['cf-btn-link']}
            href="#"
            ariaLabel={name}
            name={name}
            id={`expand-${docId}-comments-button`}
            onClick={this.toggleComments}>
            {annotationCount}
            <i className={iconClassNames}/>
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
