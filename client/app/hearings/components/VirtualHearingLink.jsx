import { css } from 'glamor';
import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { COLORS } from '../../constants/AppConstants';
import { ExternalLink } from '../../components/RenderFunctions';

const VirtualHearingLink = ({ isVirtual, newWindow, showFullLink, role, virtualHearing }) => {
  if (!isVirtual) {
    return null;
  }

  let pin;

  if (role === 'host') {
    pin = virtualHearing.hostPin;
  } else {
    pin = virtualHearing.guestPin;
  }

  const href = `https://${virtualHearing.clientHost}/webapp/\
    ?conference=${virtualHearing.alias}\
    &pin=${pin}\
    &join=1\
    &role=${role}`;

  return (
    <Link
      href={href}
      target={newWindow ? '_blank' : '_self'}
      disabled={!virtualHearing.jobCompleted}
    >
      <strong>{showFullLink ? href : 'Virtual Hearing Link'}</strong>
      <span {...css({ position: 'relative',
        top: 1 })}>
        &nbsp;<ExternalLink fill={virtualHearing.jobCompleted ? COLORS.PRIMARY : COLORS.GREY_MEDIUM} />
      </span>
    </Link>
  );
};

VirtualHearingLink.propTypes = {
  isVirtual: PropTypes.bool,
  newWindow: PropTypes.bool,
  showFullLink: PropTypes.bool,
  role: PropTypes.oneOf(['host', 'guest']).isRequired,
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
