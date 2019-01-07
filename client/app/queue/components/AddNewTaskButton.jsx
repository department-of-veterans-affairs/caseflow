import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';
import Button from '../../components/Button';
import COPY from '../../../COPY.json';
import {
  resetDecisionOptions,
  stageAppeal
} from '../QueueActions';

class AddNewTaskButton extends React.PureComponent {
  changeRoute = () => {
    const {
      rootTask,
      history
    } = this.props;

    this.props.stageAppeal(rootTask.appealId);
    this.props.resetDecisionOptions();
    const appealId = rootTask.externalAppealId;
    const uniqueId = rootTask.uniqueId;
    const modalPath = rootTask.availableActions[0].value;

    history.push(`/queue/appeals/${appealId}/tasks/${uniqueId}/${modalPath}`);
  }

  render = () => {
    return <Button
      linkStyling
      styling={css({ float: 'right',
        paddingRight: '10px' })}
      name={COPY.TASK_SNAPSHOT_ADD_NEW_TASK_LABEL}
      onClick={this.changeRoute} />;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  resetDecisionOptions,
  stageAppeal
}, dispatch);

export default (withRouter(connect(null, mapDispatchToProps)(AddNewTaskButton)): React.ComponentType<>);
