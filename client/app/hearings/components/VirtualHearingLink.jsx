import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';

import { COLORS } from '../../constants/AppConstants';
import { ExternalLink } from '../../components/RenderFunctions';
import { VIRTUAL_HEARING_HOST, virtualHearingRoleForUser } from '../utils';
import COPY from '../../../COPY';

const ICON_POSITION_FIX = css({ position: 'relative', top: 1 });

class VirtualHearingLink extends React.PureComponent {
  role = () => {
    const { user, hearing } = this.props;

    return virtualHearingRoleForUser(user, hearing);
  };

  label = () => {
    if (this.role() === VIRTUAL_HEARING_HOST) {
      return COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL;
    }

    return COPY.REPRESENTATIVE_VIRTUAL_HEARING_LINK_LABEL;
  };

  render() {
    const { isVirtual, newWindow, virtualHearing } = this.props;

    if (!isVirtual) {
      return null;
    }

    return (
      <Link href={this.props.link} target={newWindow ? '_blank' : '_self'} disabled={!virtualHearing.jobCompleted}>
        <strong>{this.props.label || this.props.link}</strong>
        <span {...ICON_POSITION_FIX}>
          &nbsp;
          <ExternalLink fill={virtualHearing.jobCompleted ? COLORS.PRIMARY : COLORS.GREY_MEDIUM} />
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
  link: PropTypes.string,
  newWindow: PropTypes.bool,
  virtualHearing: PropTypes.shape({
    clientHost: PropTypes.string,
    guestPin: PropTypes.number,
    hostPin: PropTypes.number,
    alias: PropTypes.string,
    jobCompleted: PropTypes.bool
  }).isRequired,
  label: PropTypes.string
};

VirtualHearingLink.defaultProps = {
  isVirtual: false,
  newWindow: true,
  showFullLink: false
};

export default VirtualHearingLink;
