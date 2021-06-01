import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import { COLORS } from '../../../constants/AppConstants';
import { VIRTUAL_HEARING_HOST, virtualHearingRoleForUser } from '../../utils';
import {
  rowThirds,
  labelPadding,
  labelPaddingFirst,
  hearingLinksContainer
} from './style';
import COPY from '../../../../COPY';
import CopyTextButton from '../../../components/CopyTextButton';
import VirtualHearingLink from '../VirtualHearingLink';

export const VirtualHearingLinkDetails = ({
  aliasWithHost,
  pin,
  role,
  link,
  hearing,
  wasVirtual,
  isVirtual,
  user,
  label,
  virtualHearing
}) => (
  <React.Fragment>
    {hearing?.scheduledForIsPast || wasVirtual ? (
      <span>Expired</span>
    ) : (
      <VirtualHearingLink
        label={label}
        user={user}
        virtualHearing={virtualHearing}
        isVirtual={isVirtual}
        link={link}
        hearing={hearing}
      />
    )}
    <div {...labelPaddingFirst}>
      <strong>Conference Room: </strong>
      {`${aliasWithHost}`}
    </div>
    <div {...labelPadding}>
      <strong>PIN: </strong>
      {pin}
    </div>
    {!hearing?.scheduledForIsPast && !wasVirtual && (
      <CopyTextButton label="" text={`Copy ${role} Link`} textToCopy={link} />
    )}
  </React.Fragment>
);

VirtualHearingLinkDetails.propTypes = {
  aliasWithHost: PropTypes.string,
  pin: PropTypes.oneOfType([
    PropTypes.number,
    PropTypes.string
  ]),
  role: PropTypes.string,
  link: PropTypes.string,
  hearing: PropTypes.object,
  wasVirtual: PropTypes.bool,
  isVirtual: PropTypes.bool,
  user: PropTypes.object,
  label: PropTypes.string,
  virtualHearing: PropTypes.object
};

export const LinkContainer = (
  { link, linkText, user, hearing, isVirtual, wasVirtual, virtualHearing, role, label }
) => (
  <div id={`${role.toLowerCase()}-hearings-link`} {...css({ marginTop: '1.5rem' })}>
    <strong>{label}: </strong>
    {!virtualHearing || virtualHearing?.status === 'pending' ? (
      <span {...css({ color: COLORS.GREY_MEDIUM })}>{COPY.VIRTUAL_HEARING_SCHEDULING_IN_PROGRESS}</span>
    ) : (
      <VirtualHearingLinkDetails
        label={linkText}
        user={user}
        virtualHearing={virtualHearing}
        isVirtual={isVirtual}
        wasVirtual={wasVirtual}
        hearing={hearing}
        link={link}
        role={role}
        aliasWithHost={virtualHearing?.aliasWithHost}
        pin={role === 'VLJ' ? virtualHearing?.hostPin : virtualHearing?.guestPin}
      />
    )}
  </div>
);

LinkContainer.propTypes = {
  hearing: PropTypes.object,
  isVirtual: PropTypes.bool,
  label: PropTypes.string,
  link: PropTypes.string,
  linkText: PropTypes.string,
  role: PropTypes.string,
  user: PropTypes.object,
  virtualHearing: PropTypes.object,
  wasVirtual: PropTypes.bool
};

export const HearingLinks = ({ hearing, virtualHearing, isVirtual, wasVirtual, user }) => {
  if (!isVirtual && !wasVirtual) {
    return null;
  }

  const showHostLink = virtualHearingRoleForUser(user, hearing) === VIRTUAL_HEARING_HOST;

  return (
    <div {...rowThirds} {...hearingLinksContainer}>
      {showHostLink && <LinkContainer
        hearing={hearing}
        isVirtual={isVirtual}
        label={COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL}
        link={virtualHearing?.hostLink}
        linkText={COPY.VLJ_VIRTUAL_HEARINGS_LINK_TEXT}
        role="VLJ"
        user={user}
        virtualHearing={virtualHearing}
        wasVirtual={wasVirtual}
      />}
      <LinkContainer
        hearing={hearing}
        isVirtual={isVirtual}
        label={COPY.GUEST_VIRTUAL_HEARING_LINK_LABEL}
        link={virtualHearing?.guestLink}
        linkText={COPY.GUEST_VIRTUAL_HEARINGS_LINK_TEXT}
        role="Guest"
        user={user}
        virtualHearing={virtualHearing}
        wasVirtual={wasVirtual}
      />
      <div />
    </div>
  );
};

HearingLinks.propTypes = {
  user: PropTypes.object,
  hearing: PropTypes.object,
  isVirtual: PropTypes.bool,
  wasVirtual: PropTypes.bool,
  virtualHearing: PropTypes.object
};
