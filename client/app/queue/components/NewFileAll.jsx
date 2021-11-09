import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { NewFileIcon } from '../../components/icons/NewFileIcon';
import Tooltip from '../../components/Tooltip';
import { bindActionCreators } from 'redux';
import { getNewDocumentsForTask } from '../QueueActions';
import COPY from '../../../COPY';

import _ from 'lodash';
class NewFileAll extends React.Component {
  componentDidMount = () => {
    const {
      tasks,
      documentObjects
    } = this.props;

    tasks.forEach((task) => {
      if (!documentObjects[task.taskId] ||
        (!documentObjects[task.taskId].loading && !documentObjects[task.taskId].docs)) {
        this.props.getNewDocumentsForTask(task.taskId);
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

NewFileAll.propTypes = {
  tasks: PropTypes.array,
  documentObjects: PropTypes.array,
  getNewDocumentsForTask: PropTypes.func
};

const mapStateToProps = (state, ownProps) => {
  // Get only the document objects for the give appeal IDs
  const taskIds = _.map(ownProps.tasks, 'taskId');
  const documentObjects = _.pick(state.queue.newDocsForTask, taskIds) || {};

  return { documentObjects };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getNewDocumentsForTask
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(NewFileAll));
