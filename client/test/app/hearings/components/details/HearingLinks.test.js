import React from 'react';

import { HearingLinks } from 'app/hearings/components/details/HearingLinks';
import { anyUser, vsoUser } from 'test/data/user';
import { inProgressvirtualHearing } from 'test/data/virtualHearings';
import { virtualHearing, amaHearing } from 'test/data/hearings';
import { mount } from 'enzyme';
import VirtualHearingLink from
  'app/hearings/components/VirtualHearingLink';

const hearing = {
  scheduledForIsPast: false
};

describe('HearingLinks', () => {
  test('Matches snapshot with default props when passed in', () => {
    const form = mount(
      <HearingLinks />
    );

    expect(form).toMatchSnapshot();
    expect(form.find(VirtualHearingLink)).toHaveLength(0);
  });

  test('Matches snapshot when hearing is virtual and in progress', () => {
    const form = mount(
      <HearingLinks
        hearing={hearing}
        isVirtual
        user={anyUser}
        virtualHearing={inProgressvirtualHearing}
      />
    );

    expect(form).toMatchSnapshot();
    expect(form.find(VirtualHearingLink)).toHaveLength(2);
    expect(
      form.find(VirtualHearingLink).exists({ label: 'Join Virtual Hearing' })
    ).toBe(true);
    expect(
      form.find(VirtualHearingLink).exists({ label: 'Start Virtual Hearing' })
    ).toBe(true);
  });

  test('Matches snapshot when hearing was virtual and occurred', () => {
    const form = mount(
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
      form.find('span').filterWhere((node) => node.text() === 'Expired')
    ).toHaveLength(2);
  });

  test('Only displays Guest Link when user is not a host', () => {
    const form = mount(
      <HearingLinks
        hearing={amaHearing}
        isVirtual
        user={vsoUser}
        virtualHearing={virtualHearing.virtualHearing}
      />
    );

    expect(form).toMatchSnapshot();
    expect(form.find(VirtualHearingLink)).toHaveLength(1);
    // Ensure it's the guest link
    expect(form.find(VirtualHearingLink).prop('link')).toEqual(amaHearing.virtualHearing.guestLink)
  })
});
