import { css } from 'glamor';
import React from 'react';
import VirtualHearingLink from '../VirtualHearingLink';
import { COLORS } from '../../../constants/AppConstants';
import { rowThirds, labelPadding, labelPaddingFirst, hearingLinksContainer, copyButtonStyles } from './style';
import COPY from '../../../../COPY';
import CopyTextButton from '../../../components/CopyTextButton';
import { constructURLs } from '../../utils';

export const VirtualHearingLinkDetails = ({ alias, pin, role, link, hearing }) => (
  <React.Fragment>
    <div {...labelPaddingFirst}>
      <strong>Conference Room: </strong>
      {`BVA${alias}@care.va.gov`}
    </div>
    <div {...labelPadding}>
      <strong>PIN: </strong>
      {pin}
    </div>
    {!hearing.scheduledForIsPast && (
      <CopyTextButton label="" styling={copyButtonStyles} text={`Copy ${role} Link`} textToCopy={link} />
    )}
  </React.Fragment>
);

export const LinkContainer = ({ link, user, hearing, isVirtual, virtualHearing, role, label }) => (
  <div id={`${role.toLowerCase()}-hearings-link`} {...css({ marginTop: '1.5rem' })}>
    <strong>{label}: </strong>
    {virtualHearing?.jobCompleted ? (
      <React.Fragment>
        {hearing.scheduledForIsPast ? (
          <span>Expired</span>
        ) : (
          <VirtualHearingLink
            label={COPY.OPEN_VIRTUAL_HEARINGS_LINK}
            link={link}
            user={user}
            hearing={hearing}
            isVirtual={isVirtual}
            virtualHearing={virtualHearing}
          />
        )}
        <VirtualHearingLinkDetails
          hearing={hearing}
          link={link}
          role={role}
          alias={virtualHearing.alias}
          pin={role === 'VLJ' ? virtualHearing.hostPin : virtualHearing.guestPin}
        />
      </React.Fragment>
    ) : (
      <span {...css({ color: COLORS.GREY_MEDIUM })}>{COPY.VIRTUAL_HEARING_SCHEDULING_IN_PROGRESS}</span>
    )}
  </div>
);

export const HearingLinks = ({ hearing, virtualHearing, isVirtual, label, user }) => {
  const { hostLink, guestLink } = constructURLs(virtualHearing);

  return (
    isVirtual && (
      <div {...rowThirds} {...hearingLinksContainer}>
        <LinkContainer
          role="VLJ"
          link={hostLink}
          user={user}
          hearing={hearing}
          isVirtual={isVirtual}
          virtualHearing={virtualHearing}
          label={label}
        />
        <LinkContainer
          label={COPY.GUEST_VIRTUAL_HEARING_LINK_LABEL}
          role="Guest"
          link={guestLink}
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
