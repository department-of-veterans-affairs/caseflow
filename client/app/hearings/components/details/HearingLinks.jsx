import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

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
  isVirtual,
  user,
  label,
  virtualHearing
}) => (
  <React.Fragment>
    {link ? (
      <VirtualHearingLink
        label={label}
        user={user}
        virtualHearing={virtualHearing}
        isVirtual={isVirtual}
        link={link}
        hearing={hearing}
      />
    ) : (
      <span>N/A</span>
    )}
    {hearing.conferenceProvider === 'pexip' ? (
      <>
        <div {...labelPaddingFirst}>
          <strong>Conference Room: </strong>
          {aliasWithHost || 'N/A'}
        </div>
        <div {...labelPadding}>
          <strong>PIN: </strong>
          {pin || 'N/A'}
        </div>
      </>
    ) : (
      <div {...labelPaddingFirst} className="helper-text">
        {link}
      </div>
    )}
    <CopyTextButton
      ariaLabel={`Copy ${role} Link`}
      text={`Copy ${role} Link`}
      textToCopy={link}
    />
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
  { link, linkText, user, hearing, isVirtual, wasVirtual, virtualHearing, role, label, links }
) => {
  // The pin used depends on the role and link used depends on virtual or not
  const getPin = () => {
    const isPexipHearingCoordinator = (hearing.conferenceProvider === 'pexip' && role === 'HC');

    return (role === 'VLJ' || isPexipHearingCoordinator) ? links?.hostPin : links?.guestPin;
  };

  return (
    <div id={`${role.toLowerCase()}-hearings-link`} {...css({ marginTop: '1.5rem' })}>
      <strong>{label}: </strong>
      <VirtualHearingLinkDetails
        label={linkText}
        user={user}
        virtualHearing={virtualHearing}
        isVirtual={isVirtual}
        wasVirtual={wasVirtual}
        hearing={hearing}
        link={link}
        role={role}
        aliasWithHost={isVirtual ? links?.aliasWithHost : links?.alias}
        pin={links && getPin()}
      />
    </div>
  );
};

LinkContainer.propTypes = {
  hearing: PropTypes.object,
  isVirtual: PropTypes.bool,
  label: PropTypes.string,
  link: PropTypes.string,
  linkText: PropTypes.string,
  role: PropTypes.string,
  user: PropTypes.object,
  virtualHearing: PropTypes.object,
  wasVirtual: PropTypes.bool,
  links: PropTypes.object
};

export const HearingLinks = ({ hearing, virtualHearing, isVirtual, wasVirtual, user, isCancelled }) => {
  const {
    scheduledForIsPast,
    conferenceProvider,
    dailyDocketConferenceLink,
    nonVirtualConferenceLink
  } = hearing;
  const showHostLink = virtualHearingRoleForUser(user, hearing) === VIRTUAL_HEARING_HOST;

  const getLinks = () => {
    if (scheduledForIsPast || isCancelled) {
      return null;
    } else if (isVirtual) {
      return virtualHearing;
    } else if (conferenceProvider === 'pexip') {
      return dailyDocketConferenceLink;
    } else if (conferenceProvider === 'webex') {
      return nonVirtualConferenceLink;
    }
  };

  const links = getLinks();

  return (
    <div {...rowThirds} {...hearingLinksContainer} data-testid="link-containers">
      {showHostLink && (
        <>
          <LinkContainer
            hearing={hearing}
            isVirtual={isVirtual}
            label={COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL}
            link={links?.hostLink}
            linkText={COPY.VLJ_VIRTUAL_HEARINGS_LINK_TEXT}
            role="VLJ"
            user={user}
            virtualHearing={virtualHearing}
            wasVirtual={wasVirtual}
            links={links}
          />
          <LinkContainer
            hearing={hearing}
            isVirtual={isVirtual}
            label={COPY.HC_VIRTUAL_HEARING_LINK_LABEL}
            link={conferenceProvider === 'webex' ? links?.coHostLink : links?.hostLink}
            linkText={COPY.VLJ_VIRTUAL_HEARINGS_LINK_TEXT}
            role="HC"
            user={user}
            virtualHearing={virtualHearing}
            wasVirtual={wasVirtual}
            links={links}
          />
        </>
      )}
      <LinkContainer
        hearing={hearing}
        isVirtual={isVirtual}
        label={COPY.GUEST_VIRTUAL_HEARING_LINK_LABEL}
        link={links?.guestLink}
        linkText={COPY.GUEST_VIRTUAL_HEARINGS_LINK_TEXT}
        role="Guest"
        user={user}
        virtualHearing={virtualHearing}
        wasVirtual={wasVirtual}
        links={links}
      />
    </div>
  );
};

HearingLinks.propTypes = {
  user: PropTypes.object,
  hearing: PropTypes.object,
  isVirtual: PropTypes.bool,
  wasVirtual: PropTypes.bool,
  virtualHearing: PropTypes.object,
  isCancelled: PropTypes.bool
};
