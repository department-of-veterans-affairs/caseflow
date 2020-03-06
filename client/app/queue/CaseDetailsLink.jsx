import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import { onReceiveAmaTasks } from './QueueActions';
import ApiUtil from '../util/ApiUtil';
import COPY from '../../COPY';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES';
import { subHeadTextStyle } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class CaseDetailsLink extends React.PureComponent {
  onClick = (...args) => {
    const { task, userRole } = this.props;

    // when searching for a case, we only load appeal info, no tasks
    if (task && task.status && task.status === 'assigned' && userRole === USER_ROLE_TYPES.colocated) {
      const payload = {
        data: {
          task: {
            status: 'in_progress'
          }
        }
      };

      ApiUtil.patch(`/tasks/${task.taskId}`, payload);
    }

    return this.props.onClick ? this.props.onClick(args) : true;
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

    return <span {...linkStyling} id={`veteran-name-for-task-${task.taskId}`}>
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
  userRole: PropTypes.string,
  getLinkText: PropTypes.func,
  onClick: PropTypes.func
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveAmaTasks
}, dispatch);

export default connect(null, mapDispatchToProps)(CaseDetailsLink);
