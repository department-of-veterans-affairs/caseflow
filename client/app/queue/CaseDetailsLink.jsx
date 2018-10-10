import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import { setTaskAttrs } from './QueueActions';
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

          this.props.setTaskAttrs(task.externalAppealId, preparedTasks[task.externalAppealId]);
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
      disabled,
      freshLoadOnNavigate
    } = this.props;
    const linkProps = {
      disabled,
      onClick: this.onClick,
      [freshLoadOnNavigate ? 'href' : 'to']: `/queue/appeals/${appeal.externalId}`
    };

    return <React.Fragment>
      <Link {...linkProps}>
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
  getLinkText: PropTypes.func,
  onClick: PropTypes.func,
  freshLoadOnNavigate: PropTypes.bool
};

const mapStateToProps = (state) => ({
  userRole: state.ui.userRole
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setTaskAttrs
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseDetailsLink);
