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
    const virtualHearingFields = mount(
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
    expect(virtualHearingFields.children()).toHaveLength(0);
    expect(virtualHearingFields).toMatchSnapshot();

  });

  test('Shows only hearing links with no virtualHearing', () => {
    // Run the test
    const virtualHearingFields = mount(
      <VirtualHearingFields
        update={updateSpy}
        hearing={amaHearing}
      />,

      {
        wrappingComponent: hearingDetailsWrapper(anyUser, amaHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    // Assertions
    expect(virtualHearingFields.find(ContentSection)).toHaveLength(1);
    expect(virtualHearingFields.find(HearingLinks)).toHaveLength(1);
    expect(virtualHearingFields.find('#email-section')).toHaveLength(0)
    ;
    expect(virtualHearingFields).toMatchSnapshot();
  });

  test('Shows hearing details with virtualHearing', () => {
    // Run the test
    const virtualHearingFields = mount(
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

    // Assertions
    expect(virtualHearingFields.find(ContentSection)).toHaveLength(1);
    expect(virtualHearingFields.find(HearingLinks)).toHaveLength(1);
    expect(virtualHearingFields).toMatchSnapshot();
  });
})
;
