import * as React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { NewFileIcon } from '../../components/icons/NewFileIcon';
import Tooltip from '../../components/Tooltip';
import { bindActionCreators } from 'redux';
import { getNewDocumentsForAppeal, getNewDocumentsForTask } from '../QueueActions';
import COPY from '../../../COPY';

class NewFile extends React.Component {
  componentDidMount = () => {
    if (!this.props.docsLoading && !this.props.docs) {
      if (this.props.isForTask) {
        this.props.getNewDocumentsForTask(this.props.externalId);
      } else {
        this.props.getNewDocumentsForAppeal(this.props.externalId);
      }
    }
  }

  render = () => {
    if (this.props.docs && this.props.docs.length > 0) {
      return <Tooltip id="newfile-tip" text={COPY.NEW_FILE_ICON_TOOLTIP} offset={{ top: '-10px' }}>
        <NewFileIcon />
      </Tooltip>;
    }

    return null;
  }
}

NewFile.propTypes = {
  docsLoading: PropTypes.bool,
  isForTask: PropTypes.bool,
  getNewDocumentsForTask: PropTypes.func,
  getNewDocumentsForAppeal: PropTypes.func,
  docs: PropTypes.any,
  externalId: PropTypes.any
};

const mapStateToProps = (state, ownProps) => {
  const documentObject = ownProps.isForTask ?
    state.queue.newDocsForTask[ownProps.externalId] : state.queue.newDocsForAppeal[ownProps.externalId];

  return {
    isForTask: ownProps.isForTask,
    externalId: ownProps.externalId,
    docs: documentObject ? documentObject.docs : null,
    docsLoading: documentObject ? documentObject.loading : false,
    error: documentObject ? documentObject.error : null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getNewDocumentsForAppeal,
  getNewDocumentsForTask
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(NewFile));
