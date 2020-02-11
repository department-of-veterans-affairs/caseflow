import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';

import querystring from 'querystring';

import { COLORS } from '../../constants/AppConstants';
import { ExternalLink } from '../../components/RenderFunctions';
import COPY from '../../../COPY.json';

const ICON_POSITION_FIX = css({ position: 'relative',
  top: 1 });

class VirtualHearingLink extends React.PureComponent {

  getPin() {
    const { virtualHearing } = this.props;

    return this.role() === 'host' ? virtualHearing.hostPin : virtualHearing.guestPin;
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

    return `https://${virtualHearing.clientHost}/webapp/?${decodeURIComponent(qs)}`;
  }

  role = () => {
    const { user, hearing } = this.props;

    return user.userId.toString() === hearing.judgeId || user.userCanAssignHearingSchedule ? 'host' : 'guest';
  }

  render() {
    const { isVirtual, newWindow, showFullLink, virtualHearing } = this.props;

    if (!isVirtual) {
      return null;
    }

    const href = this.getUrl();

    return (
      <Link
        href={href}
        target={newWindow ? '_blank' : '_self'}
        disabled={!virtualHearing.jobCompleted}
      >
        <strong>{showFullLink ? href : COPY.VIRTUAL_HEARING_LINK_LABEL}</strong>
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
