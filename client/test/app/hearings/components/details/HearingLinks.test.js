import React from 'react';

import { HearingLinks } from 'app/hearings/components/details/HearingLinks';
import { inProgressvirtualHearing } from 'test/data/virtualHearings';
import { mount } from 'enzyme';
import VirtualHearingLink from
  'app/hearings/components/VirtualHearingLink';

const user = {
  userCanAssignHearingSchedule: true
};
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
        user={user}
        virtualHearing={inProgressvirtualHearing}
      />
    );

    expect(form).toMatchSnapshot();
    expect(form.find(VirtualHearingLink)).toHaveLength(2);
  });
});
