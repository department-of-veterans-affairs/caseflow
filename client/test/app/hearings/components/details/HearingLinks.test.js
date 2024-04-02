import React from 'react';

import { HearingLinks } from 'app/hearings/components/details/HearingLinks';
import { anyUser, vsoUser } from 'test/data/user';
import { inProgressvirtualHearing } from 'test/data/virtualHearings';
import { virtualHearing, amaHearing, virtualWebexHearing } from 'test/data/hearings';
import VirtualHearingLink from
  'app/hearings/components/VirtualHearingLink';
import { mount } from 'enzyme';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';

describe('HearingLinks', () => {
  const storeValues = {
    dailyDocket: {
      hearingDay: {
        conferenceLink: {
          hostPin: '2949749',
          hostLink: 'https://example.va.gov/bva-app/?join=1&media=&escalate=1&conference=BVA0000031@example.va.gov&pin=2949749&role=host',
          alias: 'BVA0000130@example.va.gov',
          guestPin: '9523850278',
          guestLink: 'https://example.va.gov/sample/?conference=BVA0000130@example.va.gov&pin=9523850278&callType=video',
          coHostLink: null,
          type: 'PexipConferenceLink',
          conferenceProvider: 'pexip'
        }
      }
    }
  };
  const createReducer = (values) => {
    return function (state = values) {
      return state;
    };
  };
  const store = createStore(createReducer(storeValues), compose(applyMiddleware(thunk)));

  test('Matches snapshot when hearing is virtual, pexip, and in progress', () => {
    const hearing = {
      scheduledForIsPast: false,
      isVirtual: true,
      conferenceProvider: 'pexip'
    };

    const form = mount(
      <Provider store={store}>
        <HearingLinks
          hearing={hearing}
          isVirtual
          user={anyUser}
          virtualHearing={inProgressvirtualHearing}
        />
      </Provider>
    );

    expect(form).toMatchSnapshot();
    expect(form.find('LinkContainer')).toHaveLength(3);
    expect(
      form.find('LinkContainer').exists({ role: 'VLJ' })
    ).toBe(true);
    expect(
      form.find('VirtualHearingLinkDetails').exists({ label: 'Join Hearing' })
    ).toBe(true);
    expect(
      form.find('VirtualHearingLinkDetails').exists({ label: 'Start Hearing' })
    ).toBe(true);
    expect(form.contains(<strong>Conference Room: </strong>)).toBe(true);
    expect(form.contains(<strong>PIN: </strong>)).toBe(true);
  });

  test('Matches snapshot when hearing was virtual and occurred', () => {
    const hearing = {
      scheduledForIsPast: false,
      wasVirtual: true,
      conferenceProvider: 'pexip'
    };

    const form = mount(
      <Provider store={store}>
        <HearingLinks
          hearing={hearing}
          wasVirtual
          user={anyUser}
          virtualHearing={inProgressvirtualHearing}
        />
      </Provider>
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
      <Provider store={store}>
        <HearingLinks
          hearing={hearing}
          isVirtual
          user={anyUser}
          virtualHearing={virtualWebexHearing.virtualHearing}
        />
      </Provider>
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
      isVirtual: false,
      conferenceProvider: 'webex',
      nonVirtualConferenceLink: {
        hostPin: null,
        hostLink: 'https://instant-usgov.webex.com/visit/3k8cjyd',
        alias: null,
        guestPin: null,
        guestLink: 'https://instant-usgov.webex.com/visit/4exy2vk',
        coHostLink: 'https://instant-usgov.webex.com/visit/6yxtt4e',
        type: 'WebexConferenceLink',
        conferenceProvider: 'webex'
      }
    };
    const form = mount(
      <Provider store={store}>
        <HearingLinks
          hearing={hearing}
          isVirtual
          user={anyUser}
        />
      </Provider>
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
      isVirtual: false,
      conferenceProvider: 'pexip',
    }

    const form = mount(
      <Provider store={store}>
        <HearingLinks
          hearing={hearing}
          isVirtual
          user={anyUser}
        />
      </Provider>
    );

    expect(form).toMatchSnapshot();
    expect(form.find('LinkContainer')).toHaveLength(3);
    expect(form.find('VirtualHearingLinkDetails')).toHaveLength(3);
    expect(
      form.find('LinkContainer').exists({ link: storeValues.dailyDocket.hearingDay.conferenceLink.hostLink })
    ).toBe(true);
  });

  test('Only displays Guest Link when user is not a host', () => {
    const form = mount(
      <Provider store={store}>
        <HearingLinks
          hearing={amaHearing}
          isVirtual
          user={vsoUser}
          virtualHearing={virtualHearing.virtualHearing}
        />
      </Provider>
    );

    expect(form).toMatchSnapshot();
    expect(form.find(VirtualHearingLink)).toHaveLength(1);
    // Ensure it's the guest link
    expect(form.find(VirtualHearingLink).prop('link')).toEqual(amaHearing.virtualHearing.guestLink);
  });
});
