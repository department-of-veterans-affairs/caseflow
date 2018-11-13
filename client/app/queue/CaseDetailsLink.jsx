import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import { onReceiveAmaTasks } from './QueueActions';
import ApiUtil from '../util/ApiUtil';
import COPY from '../../COPY.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import { subHeadTextStyle } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { prepareTasksForStore } from './utils';

class CaseDetailsLink extends React.PureComponent {
  onClick = () => {
    const { task } = this.props;

    // when searching for a case, we only load appeal info, no tasks
    if (task && task.status && task.status === 'assigned') {
      const payload = {
        data: {
          task: {
            status: 'in_progress'
          }
        }
      };

      ApiUtil.patch(`/tasks/${task.taskId}`, payload).
        then((resp) => {
          const response = JSON.parse(resp.text);
          const preparedTasks = prepareTasksForStore(response.tasks.data);

          this.props.onReceiveAmaTasks(preparedTasks);
        });
    }

    return this.props.onClick ? this.props.onClick(arguments) : true;
  }

  getLinkText = () => {
    const {
      task,
      appeal,
      userRole
    } = this.props;

    if (this.props.getLinkText) {
      return this.props.getLinkText(appeal, task);
    }

    const linkStyling = css({
      fontWeight: (task.status === 'assigned' && userRole === USER_ROLE_TYPES.colocated) ? 'bold' : null
    });

    return <span {...linkStyling}>
      {appeal.veteranFullName} ({appeal.veteranFileNumber})
    </span>;
  }

  render() {
    const {
      appeal,
      disabled
    } = this.props;

    return <React.Fragment>
      <Link
        to={`/queue/appeals/${appeal.externalId}`}
        disabled={disabled}
        onClick={this.onClick}>
        {this.getLinkText()}
      </Link>
      {appeal.isPaperCase && <React.Fragment>
        <br />
        <span {...subHeadTextStyle}>{COPY.IS_PAPER_CASE}</span>
      </React.Fragment>}
    </React.Fragment>;
  }
}

CaseDetailsLink.propTypes = {
  task: PropTypes.object,
  appeal: PropTypes.object.isRequired,
  disabled: PropTypes.bool,
  userRole: PropTypes.string.isRequired,
  getLinkText: PropTypes.func,
  onClick: PropTypes.func
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveAmaTasks
}, dispatch);

export default connect(null, mapDispatchToProps)(CaseDetailsLink);
