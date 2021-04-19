import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';

import { COLORS } from '../../constants/AppConstants';
import { ExternalLink } from '../../components/RenderFunctions';

const ICON_POSITION_FIX = css({ position: 'relative', top: 1 });

const VirtualHearingLink = ({
  isVirtual,
  newWindow,
  link,
  virtualHearing,
  label
}) => {
  if (!isVirtual) {
    return null;
  }

  return (
    <Link href={link} target={newWindow ? '_blank' : '_self'} disabled={!virtualHearing.jobCompleted}>
      <strong>{label}</strong>
      <span {...ICON_POSITION_FIX}>
        &nbsp;
        <ExternalLink fill={virtualHearing.jobCompleted ? COLORS.PRIMARY : COLORS.GREY_MEDIUM} />
      </span>
    </Link>
  );
};

VirtualHearingLink.propTypes = {
  isVirtual: PropTypes.bool,
  link: PropTypes.string,
  newWindow: PropTypes.bool,
  virtualHearing: PropTypes.shape({
    status: PropTypes.string,
    guestPin: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.string
    ]),
    hostPin: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.string
    ]),
    aliasWithHost: PropTypes.string,
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
