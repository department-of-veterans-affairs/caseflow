import React from 'react';
import { mount } from 'enzyme';

// Component under test
import { VirtualHearingFields } from 'app/hearings/components/details/VirtualHearingFields';

// Additional components
import { ContentSection } from 'app/components/ContentSection';
import { HearingLinks } from 'app/hearings/components/details/HearingLinks';

// Test helpers and data
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import { anyUser, amaHearing, defaultHearing, virtualHearing } from 'test/data';

// Setup the spies
const updateSpy = jest.fn();

describe('VirtualHearingFields', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const virtualHearingForm = mount(
      <VirtualHearingFields
        update={updateSpy}
        hearing={defaultHearing}
      />,

      {
        wrappingComponent: hearingDetailsWrapper(anyUser, defaultHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    // Assertions
    expect(virtualHearingForm.children()).toHaveLength(1);
    expect(virtualHearingForm).toMatchSnapshot();
  });

  test('Shows only hearing links with no virtualHearing', () => {
    // Run the test
    const virtualHearingForm = mount(
      <VirtualHearingFields
        update={updateSpy}
        hearing={amaHearing}
        virtualHearing={amaHearing.virtualHearing}
      />,

      {
        wrappingComponent: hearingDetailsWrapper(anyUser, amaHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    // Assertions
    expect(virtualHearingForm.find(ContentSection)).toHaveLength(1);
    expect(virtualHearingForm.find(HearingLinks)).toHaveLength(1);

    expect(virtualHearingForm).toMatchSnapshot();
  });

  test('Shows hearing details with virtualHearing', () => {
    // Run the test
    const virtualHearingForm = mount(
      <VirtualHearingFields
        update={updateSpy}
        hearing={amaHearing}
        virtualHearing={virtualHearing.virtualHearing}
      />,

      {
        wrappingComponent: hearingDetailsWrapper(anyUser, amaHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    const hearingMeetingType = amaHearing.judge.meetingType;

    // Assertions
    expect(virtualHearingForm.find(ContentSection)).toHaveLength(1);
    expect(virtualHearingForm.find(HearingLinks)).toHaveLength(1);
    expect(hearingMeetingType).toBeTruthy();
    expect(hearingMeetingType).toStrictEqual('pexip' || 'webex');

    expect(virtualHearingForm).toMatchSnapshot();
  });

  test('Renders webex conference when conference provider is webex', () => {
    const webexHearing = {
      ...amaHearing,
      conferenceProvider: 'webex'
    };

    // Run the test
    const virtualHearingForm = mount(
      <VirtualHearingFields
        update={updateSpy}
        hearing={webexHearing}
        virtualHearing={{
          ...virtualHearing.virtualHearing,
          conferenceProvider: 'webex'
        }}
      />,

      {
        wrappingComponent: hearingDetailsWrapper(anyUser, webexHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    // Assertions
    expect(virtualHearingForm.text().includes('Webex Hearing')).toBeTruthy();

    expect(virtualHearingForm).toMatchSnapshot();
  });

  test('Renders pexip conference when conference provider is pexip', () => {
    const webexHearing = {
      ...amaHearing,
      conferenceProvider: 'pexip'
    };

    // Run the test
    const virtualHearingForm = mount(
      <VirtualHearingFields
        update={updateSpy}
        hearing={webexHearing}
        virtualHearing={{
          ...virtualHearing.virtualHearing,
          conferenceProvider: 'pexip'
        }}
      />,

      {
        wrappingComponent: hearingDetailsWrapper(anyUser, webexHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    // Assertions
    expect(virtualHearingForm.text().includes('Pexip Hearing')).toBeTruthy();

    expect(virtualHearingForm).toMatchSnapshot();
  });
});
