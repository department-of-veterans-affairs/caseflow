import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import { makeGetAnnotationsByDocumentId } from './selectors';
import { ChevronDownIcon } from '../components/icons/ChevronDownIcon';
import { ChevronUpIcon } from '../components/icons/ChevronUpIcon';
import Button from '../components/Button';
import { handleToggleCommentOpened } from '../reader/Documents/DocumentsActions';

class DocSizeIndicator extends React.Component {
  // shouldComponentUpdate = (nextProps) => !_.isEqual(this.props, nextProps)

  // toggleComments = () => this.props.handleToggleCommentOpened(this.props.docSize, this.props.expanded)

  render() {

    return <span> 1
    </span>;
  }
}

const mapStateToProps = (state, ownProps) => {
// const doc = state.documents[ownProps.docId];

  return {
    docSize: 1,
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
)(DocSizeIndicator);
