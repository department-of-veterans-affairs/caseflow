import React from 'react';

import { HearingLinks } from 'app/hearings/components/details/HearingLinks';
import { anyUser, vsoUser, hearingUser } from 'test/data/user';
import { inProgressvirtualHearing } from 'test/data/virtualHearings';
import { virtualHearing, amaHearing, virtualWebexHearing } from 'test/data/hearings';
import { render, screen, logRoles } from '@testing-library/react';
import COPY from 'COPY';

describe('HearingLinks', () => {
  test('Matches snapshot when hearing is virtual, pexip, and in progress', () => {
    const hearing = {
      scheduledForIsPast: false,
      conferenceProvider: 'pexip',
      isVirtual: true
    };

    const {asFragment, container} = render(
      <HearingLinks
        hearing={hearing}
        isVirtual
        user={anyUser}
        virtualHearing={inProgressvirtualHearing}
      />
    );

    expect(asFragment()).toMatchSnapshot();
    expect(screen.getByTestId('link-containers')).toBeInTheDocument();
    expect(screen.getByText(`${COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL}:`)).toBeInTheDocument();
    expect(screen.getByText('Join Hearing')).toBeInTheDocument();
    expect(screen.getAllByText('Start Hearing').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Conference Room:').length).toBeGreaterThan(0);
    expect(screen.getAllByText('PIN:').length).toBeGreaterThan(0);
  });

  test('Matches snapshot when hearing was virtual and occurred', () => {
    const hearing = {
      scheduledForIsPast: false,
      wasVirtual: true,
      conferenceProvider: 'pexip'
    };

    const {asFragment} = render(
      <HearingLinks
        hearing={hearing}
        wasVirtual
        user={anyUser}
        virtualHearing={inProgressvirtualHearing}
      />
    );

    expect(asFragment()).toMatchSnapshot();
    expect(screen.queryByTestId("strong-element-test-id")).toBeNull();
    const spanElements = screen.getAllByText('N/A', { selector: 'span' });
    expect(spanElements.length).toBe(3);
  });

  test('Matches snapshot when hearing is virtual, webex, and in progress', () => {
    const hearing = {
      scheduledForIsPast: false,
      isVirtual: true,
      conferenceProvider: 'webex'
    };

    const {asFragment} = render(
      <HearingLinks
        hearing={hearing}
        isVirtual
        user={anyUser}
        virtualHearing={virtualWebexHearing.virtualHearing}
      />
    );

    expect(asFragment()).toMatchSnapshot();
    expect(screen.getAllByTestId('strong-element-test-id').length).toBe(3);
    expect(screen.getByText('Join Hearing')).toBeInTheDocument();
    expect(screen.getAllByText('Start Hearing').length).toBeGreaterThan(0);
    expect(screen.getByText(virtualWebexHearing.virtualHearing.hostLink)).toBeInTheDocument();
  });

  test('Matches snapshot when hearing is non-virtual, webex, and in progress', () => {
    const hearing = {
      scheduledForIsPast: false,
      conferenceProvider: 'webex',
      nonVirtualConferenceLink: {
        alias: null,
        coHostLink: 'https://instant-usgov.webex.com/visit/yqju5qi',
        conferenceProvider: 'webex',
        guestLink: 'https://instant-usgov.webex.com/visit/m9p1k56',
        guestPin: null,
        hostLink: 'https://instant-usgov.webex.com/visit/owhuy7m',
        hostPin: null,
        type: 'WebexConferenceLink'
      }
    };
    const {asFragment} = render(
      <HearingLinks
        hearing={hearing}
        isVirtual={false}
        user={anyUser}
      />
    );

    expect(asFragment()).toMatchSnapshot();
    expect(screen.getByTestId('link-containers')).toBeInTheDocument();
    expect(screen.getAllByTestId('strong-element-test-id').length).toBe(3);
    expect(screen.getByText(hearing.nonVirtualConferenceLink.hostLink)).toBeInTheDocument();
  });

  test('Matches snapshot when hearing is non-virtual, pexip, and in progress', () => {
    const hearing = {
      scheduledForIsPast: false,
      wasVirtual: false,
      conferenceProvider: 'pexip',
      readableRequestType: 'Video',
      dailyDocketConferenceLink: {
        alias: 'BVA0001094@example.va.gov',
        coHostLink: null,
        conferenceProvider: 'pexip',
        guestLink: 'https://example.va.gov/sample/?conference=BVA0001094@example.va.gov&pin=1342380867&callType=video',
        guestPin: '1342380867',
        hearingDayId: 151,
        hostLink: 'https://example.va.gov/bva-app/?join=1&media=&escalate=1&conference=BVA0001094@example.va.gov&pin=1073526&role=host',
        hostPin: '1073526',
        type: 'PexipConferenceLink'
      }
    };

    const {asFragment} = render(
      <HearingLinks
        hearing={hearing}
        isVirtual={false}
        user={anyUser}
      />
    );

    expect(asFragment()).toMatchSnapshot();
    expect(screen.getByTestId('link-containers')).toBeInTheDocument();
    expect(screen.getAllByTestId('strong-element-test-id').length).toBe(3);

    const linkElements = screen.getAllByRole('link', { name: "Start Hearing" });
    linkElements.forEach((element) => {
    expect(element).toHaveAttribute('href', hearing.dailyDocketConferenceLink.hostLink);
  });
  });

  test('Only displays Guest Link when user is not a host', () => {
    const {asFragment, container} = render(
      <HearingLinks
        hearing={amaHearing}
        isVirtual
        user={vsoUser}
        virtualHearing={virtualHearing.virtualHearing}
      />
    );

    expect(asFragment()).toMatchSnapshot();
    expect(screen.getByTestId('strong-element-test-id')).toBeInTheDocument();
    expect(screen.getAllByTestId('strong-element-test-id').length).toBe(1);

    // Ensure it's the guest link
    const link = screen.getByRole('link', { name: 'Join Hearing' });
    expect(link).toHaveAttribute('href', virtualHearing.virtualHearing.guestLink);
  });

  test('Display NA for links when hearing is cancelled', () => {
    render(
      <HearingLinks
        hearing={amaHearing}
        isVirtual
        user={hearingUser}
        virtualHearing={virtualHearing.virtualHearing}
        isCancelled
      />
    );

    expect(screen.getAllByText('N/A').length).toBe(9);
  });
});
