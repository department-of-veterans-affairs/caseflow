import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import QueueFlowModal from './QueueFlowModal';
import { requestSave } from '../uiReducer/uiActions';
import { taskById } from '../selectors';
import { withRouter } from 'react-router-dom';

class CorrespondencePickerModal extends React.Component {
  render = () => <QueueFlowModal
    title="Download pre-filled correspondence"
    pathAfterSubmit={`/queue/appeals/${this.props.appealId}`}
    button="Done" 
    submit={() => Promise.resolve()}
  >
    <p>Download Word document with relevant information about appeal already populated.</p>
    <ul>
      <li><a href={`/correspondence/${this.props.task.taskId}/example`}>Example document</a></li>
    </ul>
  </QueueFlowModal>;
}

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(CorrespondencePickerModal));
