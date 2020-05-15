import { css } from 'glamor';
import React from 'react';
import VirtualHearingLink from '../VirtualHearingLink';
import { COLORS } from '../../../constants/AppConstants';
import { rowThirds, labelPadding, labelPaddingFirst, hearingLinksContainer, copyButtonStyles } from './style';
import COPY from '../../../../COPY';
import CopyTextButton from '../../../components/CopyTextButton';
import PropTypes from 'prop-types';

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
      <CopyTextButton label="" styling={copyButtonStyles} text={`Copy ${role} Link`} textToCopy={link} />
    )}
  </React.Fragment>
);

VirtualHearingLinkDetails.propTypes = {
  aliasWithHost: PropTypes.string,
  pin: PropTypes.number,
  role: PropTypes.string,
  link: PropTypes.string,
  hearing: PropTypes.object,
  wasVirtual: PropTypes.bool,
  isVirtual: PropTypes.bool,
  user: PropTypes.object,
  label: PropTypes.string,
  virtualHearing: PropTypes.object
};

export const LinkContainer = ({ link, user, hearing, isVirtual, wasVirtual, virtualHearing, role, label }) => (
  <div id={`${role.toLowerCase()}-hearings-link`} {...css({ marginTop: '1.5rem' })}>
    <strong>{label}: </strong>
    {!virtualHearing || virtualHearing?.status === 'pending' ? (
      <span {...css({ color: COLORS.GREY_MEDIUM })}>{COPY.VIRTUAL_HEARING_SCHEDULING_IN_PROGRESS}</span>
    ) : (
      <VirtualHearingLinkDetails
        label={COPY.OPEN_VIRTUAL_HEARINGS_LINK}
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
  link: PropTypes.string,
  user: PropTypes.object,
  hearing: PropTypes.object,
  isVirtual: PropTypes.bool,
  wasVirtual: PropTypes.bool,
  virtualHearing: PropTypes.object,
  label: PropTypes.string,
  role: PropTypes.string
};

export const HearingLinks = ({ hearing, virtualHearing, isVirtual, wasVirtual, label, user }) => {
  return (
    (isVirtual || wasVirtual) && (
      <div {...rowThirds} {...hearingLinksContainer}>
        <LinkContainer
          wasVirtual={wasVirtual}
          role="VLJ"
          link={virtualHearing?.hostLink}
          user={user}
          hearing={hearing}
          isVirtual={isVirtual}
          virtualHearing={virtualHearing}
          label={label}
        />
        <LinkContainer
          wasVirtual={wasVirtual}
          label={COPY.GUEST_VIRTUAL_HEARING_LINK_LABEL}
          role="Guest"
          link={virtualHearing?.guestLink}
          user={user}
          hearing={hearing}
          isVirtual={isVirtual}
          virtualHearing={virtualHearing}
        />
        <div />
      </div>
    )
  );
};

HearingLinks.propTypes = {
  user: PropTypes.object,
  hearing: PropTypes.object,
  isVirtual: PropTypes.bool,
  wasVirtual: PropTypes.bool,
  virtualHearing: PropTypes.object,
  label: PropTypes.string
};
