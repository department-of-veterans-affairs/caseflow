import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';

import { COLORS } from '../../constants/AppConstants';
import { ExternalLinkIcon } from '../../components/icons/ExternalLinkIcon';

const ICON_POSITION_FIX = css({ position: 'relative', top: 1 });

const VirtualHearingLink = ({
  newWindow,
  link,
  label,
  hearing
}) => {
  return (
    <Link
      href={link}
      target={newWindow ? '_blank' : '_self'}
    >
      <strong>{label}</strong>
      <span {...ICON_POSITION_FIX}>
        &nbsp;
        <ExternalLinkIcon color={hearing?.scheduledForIsPast ? COLORS.PRIMARY : COLORS.GREY_MEDIUM} />
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
  }),
  label: PropTypes.string,
  hearing: PropTypes.shape({
    dailyDocketConferenceLinks: PropTypes.shape({
      coHostLink: PropTypes.string
    })
  })
};

VirtualHearingLink.defaultProps = {
  isVirtual: false,
  newWindow: true,
  showFullLink: false
};

export default VirtualHearingLink;
