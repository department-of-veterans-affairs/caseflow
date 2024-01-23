import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { ICON_SIZES, COLORS } from 'app/constants/AppConstants';
import { onReceiveAmaTasks } from './QueueActions';
import COPY from '../../COPY';
import { subHeadTextStyle } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { ExternalLinkIcon } from '../components/icons/ExternalLinkIcon';

class CaseDetailsLink extends React.PureComponent {
  onClick = (...args) => this.props.onClick ? this.props.onClick(args) : true;

  getLinkText = () => {
    const {
      task,
      appeal
    } = this.props;

    if (this.props.getLinkText) {
      return this.props.getLinkText(appeal, task);
    }

    const linkStyling = css({
      fontWeight: task.startedAt ? null : 'bold'
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
      {this.props.linkOpensInNewTab ?
        <Link
          href={`/queue/appeals/${appeal.externalId}`}
          target="_blank"
          disabled={disabled}
          onClick={this.onClick}>
          <strong>{this.getLinkText()}</strong>
          <span className="cf-pdf-external-link-icon">
            &nbsp;
            <ExternalLinkIcon color={COLORS.PRIMARY} size={ICON_SIZES.SMALL} />
          </span>
        </Link> :
        <Link
          href={`/queue/appeals/${appeal.externalId}`}
          disabled={disabled}
          onClick={this.onClick}>
          {this.getLinkText()}
        </Link>}
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
  onClick: PropTypes.func,
  linkOpensInNewTab: PropTypes.bool
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveAmaTasks
}, dispatch);

export default connect(null, mapDispatchToProps)(CaseDetailsLink);
