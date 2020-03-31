import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';

import querystring from 'querystring';

import { COLORS } from '../../constants/AppConstants';
import { ExternalLink } from '../../components/RenderFunctions';
import { VIRTUAL_HEARING_HOST, virtualHearingRoleForUser } from '../utils';
import COPY from '../../../COPY';

const ICON_POSITION_FIX = css({ position: 'relative',
  top: 1 });

class VirtualHearingLink extends React.PureComponent {

  getPin() {
    const { virtualHearing } = this.props;

    return this.role() === VIRTUAL_HEARING_HOST ? virtualHearing.hostPin : virtualHearing.guestPin;
  }

  getUrl() {
    const { virtualHearing } = this.props;
    const qs = querystring.stringify(
      {
        conference: virtualHearing.alias,
        pin: `${this.getPin()}#`,
        join: 1,
        role: this.role()
      }
    );

    return `https://${virtualHearing.clientHost}/bva-app/?${decodeURIComponent(qs)}`;
  }

  role = () => {
    const { user, hearing } = this.props;

    return virtualHearingRoleForUser(user, hearing);
  }

  label = () => {
    const { showFullLink } = this.props;

    if (showFullLink) {
      return this.getUrl();
    }

    if (this.role() === VIRTUAL_HEARING_HOST) {
      return COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL;
    }

    return COPY.REPRESENTATIVE_VIRTUAL_HEARING_LINK_LABEL;
  }

  render() {
    const { isVirtual, newWindow, virtualHearing } = this.props;

    if (!isVirtual) {
      return null;
    }

    return (
      <Link
        href={this.getUrl()}
        target={newWindow ? '_blank' : '_self'}
        disabled={!virtualHearing.jobCompleted}
      >
        <strong>{this.label()}</strong>
        <span {...ICON_POSITION_FIX}>
          &nbsp;<ExternalLink fill={virtualHearing.jobCompleted ? COLORS.PRIMARY : COLORS.GREY_MEDIUM} />
        </span>
      </Link>
    );
  }
}

VirtualHearingLink.propTypes = {
  hearing: PropTypes.shape({
    judgeId: PropTypes.number
  }),
  user: PropTypes.shape({
    userId: PropTypes.number,
    userCanAssignHearingSchedule: PropTypes.bool
  }),
  isVirtual: PropTypes.bool,
  newWindow: PropTypes.bool,
  showFullLink: PropTypes.bool,
  virtualHearing: PropTypes.shape({
    clientHost: PropTypes.string,
    guestPin: PropTypes.number,
    hostPin: PropTypes.number,
    alias: PropTypes.string,
    jobCompleted: PropTypes.bool
  }).isRequired
};

VirtualHearingLink.defaultProps = {
  isVirtual: false,
  newWindow: true,
  showFullLink: false
};

export default VirtualHearingLink;
