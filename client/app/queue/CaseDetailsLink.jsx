import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import ApiUtil from '../util/ApiUtil';
import COPY from '../../COPY.json';
import { subHeadTextStyle } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const defaultLinkText = (appeal, task) => {
  const linkStyling = css({
    fontWeight: task.status === 'assigned' ? 'bold' : null
  });

  return <span {...linkStyling}>
    {appeal.veteranFullName} ({appeal.veteranFileNumber})
  </span>;
};

export default class CaseDetailsLink extends React.PureComponent {
  onClick = () => {
    const { task } = this.props;
    const payload = {
      data: {
        task: {
          status: 'in_progress'
        }
      }
    };
    ApiUtil.patch(`/tasks/${task.taskId}`, payload);

    return this.props.onClick ? this.props.onClick(arguments) : true;
  }

  render() {
    const {
      task,
      appeal,
      disabled
    } = this.props;

    return <React.Fragment>
      <Link
        to={`/queue/appeals/${appeal.externalId}`}
        disabled={disabled}
        onClick={this.onClick}>
        {this.props.getLinkText(appeal, task)}
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
  getLinkText: PropTypes.func.isRequired,
  onClick: PropTypes.func
};

CaseDetailsLink.defaultProps = {
  getLinkText: defaultLinkText
};
