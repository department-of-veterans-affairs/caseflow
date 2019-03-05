import * as React from 'react';
import { connect } from 'react-redux';
import { NewFileIcon } from '../../components/RenderFunctions';
import Tooltip from '../../components/Tooltip';
import { bindActionCreators } from 'redux';
import { getNewDocumentsForTask } from '../QueueActions';
import COPY from '../../../COPY.json';

import _ from 'lodash';

class NewFileAll extends React.Component {
  componentDidMount = () => {
    const {
      tasks,
      documentObjects
    } = this.props;

    tasks.forEach((task) => {
      if (!documentObjects[task.uniqueId] ||
        (!documentObjects[task.uniqueId].loading && !documentObjects[task.uniqueId].docs)) {
        this.props.getNewDocumentsForTask(task.uniqueId);
      }
    });
  }

  render = () => {
    // Check to see if there are any new documents for any appeals
    const allDocs = _.filter(_.map(this.props.documentObjects, 'docs'), (docs) => docs && docs.length);

    if (allDocs && allDocs.length) {
      return <Tooltip id="newfileall-tip" text={COPY.NEW_FILE_ALL_ICON_TOOLTIP} offset={{ top: '-10px' }}>
        <NewFileIcon />
      </Tooltip>;
    }

    return null;

  }
}

const mapStateToProps = (state, ownProps) => {
  // Get only the document objects for the give appeal IDs
  const uniqueIds = _.map(ownProps.tasks, 'uniqueId');
  const documentObjects = _.pick(state.queue.newDocsForTask, uniqueIds) || {};

  return { documentObjects };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getNewDocumentsForTask
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(NewFileAll));
