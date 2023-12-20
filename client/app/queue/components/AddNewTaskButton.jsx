import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import Button from '../../components/Button';
import COPY from '../../../COPY.json';
import { rootTasksForAppeal } from '../selectors';
const buttonStyling = css({
  float: 'right',
  paddingRight: '10px'
});

class AddNewTaskButton extends React.PureComponent {
  changeRoute = () => {
    const {
      rootTask,
      history
    } = this.props;

    const appealId = rootTask.externalAppealId;
    const uniqueId = rootTask.uniqueId;
    const modalPath = rootTask.availableActions[0].value;

    history.push(`/queue/appeals/${appealId}/tasks/${uniqueId}/${modalPath}`);
  }

  render = () => {
    const {
      rootTask
    } = this.props;

    return (rootTask) ? <Button
      linkStyling
      styling={buttonStyling}
      name={COPY.TASK_SNAPSHOT_ADD_NEW_TASK_LABEL}
      onClick={this.changeRoute} /> : null;
  }
}

const mapStateToProps = (state, ownProps) => {

  return {
    rootTask: rootTasksForAppeal(state, { appealId: ownProps.appealId })[0]
  };
};

export default (withRouter(connect(mapStateToProps, null)(AddNewTaskButton)));
