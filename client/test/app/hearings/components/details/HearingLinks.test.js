import React from 'react';

import { logRoles } from '@testing-library/react';
import { HearingLinks } from 'app/hearings/components/details/HearingLinks';
import { anyUser, vsoUser, hearingUser } from 'test/data/user';
import { inProgressvirtualHearing } from 'test/data/virtualHearings';
import { virtualHearing, amaHearing, virtualWebexHearing } from 'test/data/hearings';
import { render, screen } from "@testing-library/react";
import { render, screen } from '@testing-library/react';
import VirtualHearingLink from
  'app/hearings/components/VirtualHearingLink';

describe('HearingLinks', () => {
  test('Matches snapshot with default props when passed in', () => {
    render(<HearingLinks />);

    const virtualHearingLink = screen.queryByTestId("strong-element-test-id");
    expect(virtualHearingLink).not.toBeInTheDocument();
  });

  test('Matches snapshot when hearing is virtual and in progress', () => {
    const {asFragment} = render(
      <HearingLinks
        hearing={hearing}
        isVirtual
        user={anyUser}
        virtualHearing={inProgressvirtualHearing}
      />
    );

    expect(asFragment()).toMatchSnapshot();

    const elementsWithTestId = screen.getAllByTestId("strong-element-test-id");
    expect(elementsWithTestId.length).toEqual(2);

    const joinHearing = screen.getByText("Join Virtual Hearing");
    expect(joinHearing).toBeInTheDocument();

    const startHearing = screen.getByText("Start Virtual Hearing");
    expect(startHearing).toBeInTheDocument();
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

    expect(form).toMatchSnapshot();
    expect(form.find(VirtualHearingLink)).toHaveLength(0);
    expect(
      form.find('span').filterWhere((node) => node.text() === 'N/A')
    ).toHaveLength(3);
  });

  test('Matches snapshot when hearing is virtual, webex, and in progress', () => {
    const hearing = {
      scheduledForIsPast: false,
      isVirtual: true,
      conferenceProvider: 'webex'
    };

    const form = mount(
      <HearingLinks
        hearing={hearing}
        isVirtual
        user={anyUser}
        virtualHearing={virtualWebexHearing.virtualHearing}
      />
    );

    expect(form).toMatchSnapshot();
    expect(form.find('VirtualHearingLinkDetails')).toHaveLength(3);
    expect(
      form.find('VirtualHearingLinkDetails').exists({ label: 'Join Hearing' })
    ).toBe(true);
    expect(
      form.find('VirtualHearingLinkDetails').exists({ label: 'Start Hearing' })
    ).toBe(true);
    expect(
      form.find('LinkContainer').exists({ link: virtualWebexHearing.virtualHearing.hostLink })
    ).toBe(true);
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
    const form = mount(
      <HearingLinks
        hearing={hearing}
        isVirtual={false}
        user={anyUser}
      />
    );

    expect(form).toMatchSnapshot();
    expect(form.find('LinkContainer')).toHaveLength(3);
    expect(form.find('VirtualHearingLinkDetails')).toHaveLength(3);
    expect(
      form.find('LinkContainer').exists({ link: hearing.nonVirtualConferenceLink.hostLink })
    ).toBe(true);
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

    const form = mount(
      <HearingLinks
        hearing={hearing}
        isVirtual={false}
        user={anyUser}
      />
    );

    expect(form).toMatchSnapshot();
    expect(form.find('LinkContainer')).toHaveLength(3);
    expect(form.find('VirtualHearingLinkDetails')).toHaveLength(3);
    expect(
      form.find('LinkContainer').exists({ link: hearing.dailyDocketConferenceLink.hostLink })
    ).toBe(true);
  });

  test('Only displays Guest Link when user is not a host', () => {
    const {asFragment} =render(
      <HearingLinks
        hearing={amaHearing}
        isVirtual
        user={vsoUser}
        virtualHearing={virtualHearing.virtualHearing}
      />
    );

    expect(asFragment).toMatchSnapshot();

    const elementsWithTestId = screen.getAllByTestId("strong-element-test-id");
    expect(elementsWithTestId.length).toEqual(1);

    // Ensure it's the guest link
    expect(screen.getByRole("button", { name: /guest link/i })).toBeInTheDocument();;
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
