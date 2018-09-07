import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { css } from 'glamor';

import ApiUtil from '../util/ApiUtil';
import COPY from '../../COPY.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import { subHeadTextStyle } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class CaseDetailsLink extends React.PureComponent {
  onClick = () => {
    const {
      task,
      appeal
    } = this.props;

    if (appeal.docketName !== 'legacy') {
      const payload = {
        data: {
          task: {
            status: 'in_progress'
          }
        }
      };
      ApiUtil.patch(`/tasks/${task.taskId}`, payload);
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

    // only bold links for colocated users, for 'assigned' tasks
    const shouldBold = task.status === 'assigned' && userRole === USER_ROLE_TYPES.colocated;
    const linkStyling = css({ fontWeight: shouldBold ? 'bold' : null });

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
  getLinkText: PropTypes.func,
  onClick: PropTypes.func
};

const mapStateToProps = (state) => ({
  userRole: state.ui.userRole
});

export default connect(mapStateToProps)(CaseDetailsLink);