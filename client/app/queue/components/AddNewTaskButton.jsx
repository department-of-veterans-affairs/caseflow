import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import Button from '../../components/Button';
import COPY from '../../../COPY.json';
import type { State } from '../types/state';
import { rootTasksForAppeal } from '../selectors';
const buttonStyling = css({
  float: 'right',
  paddingRight: '10px'
});

type Params = {|
  appealId: string
|};

class AddNewTaskButton extends React.PureComponent {
  changeRoute = () => {
    const {
      rootTask,
      history
    } = this.props;

    const appealId = rootTask[0].externalAppealId;
    const uniqueId = rootTask[0].uniqueId;
    const modalPath = rootTask[0].availableActions[0].value;

    history.push(`/queue/appeals/${appealId}/tasks/${uniqueId}/${modalPath}`);
  }

  render = () => {
    const {
      rootTask
    } = this.props;

    return (rootTask[0]) ? <Button
      linkStyling
      styling={buttonStyling}
      name={COPY.TASK_SNAPSHOT_ADD_NEW_TASK_LABEL}
      onClick={this.changeRoute} /> : null;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {

  return {
    rootTask: rootTasksForAppeal(state, { appealId: ownProps.appealId })
  };
};

export default (withRouter(connect(mapStateToProps, null)(AddNewTaskButton)): React.ComponentType<>);
