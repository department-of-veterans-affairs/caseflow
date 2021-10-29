import React from 'react';
import { mount } from 'enzyme';

// Component under test
import { VirtualHearingForm } from 'app/hearings/components/details/VirtualHearingForm';

// Additional components
import { ContentSection } from 'app/components/ContentSection';
import { HearingLinks } from 'app/hearings/components/details/HearingLinks';

// Test helpers and data
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import { anyUser, amaHearing, defaultHearing, virtualHearing } from 'test/data';

// Setup the spies
const updateSpy = jest.fn();

describe('VirtualHearingForm', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const virtualHearingForm = mount(
      <VirtualHearingForm
        update={updateSpy}
        hearing={defaultHearing}
      />,

      {
        wrappingComponent: hearingDetailsWrapper(anyUser, defaultHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    // Assertions
    expect(virtualHearingForm.children()).toHaveLength(0);
    expect(virtualHearingForm).toMatchSnapshot();

  });

  test('Shows only hearing links with no virtualHearing', () => {
    // Run the test
    const virtualHearingForm = mount(
      <VirtualHearingForm
        update={updateSpy}
        hearing={amaHearing}
      />,

      {
        wrappingComponent: hearingDetailsWrapper(anyUser, amaHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    // Assertions
    expect(virtualHearingForm.find(ContentSection)).toHaveLength(1);
    expect(virtualHearingForm.find(HearingLinks)).toHaveLength(1);
    expect(virtualHearingForm.find('#email-section')).toHaveLength(0)
    ;
    expect(virtualHearingForm).toMatchSnapshot();
  });

  test('Shows hearing details with virtualHearing', () => {
    // Run the test
    const virtualHearingForm = mount(
      <VirtualHearingForm
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
    expect(virtualHearingForm.find(ContentSection)).toHaveLength(1);
    expect(virtualHearingForm.find(HearingLinks)).toHaveLength(1);
    expect(virtualHearingForm.find('#email-section')).toHaveLength(1)
    ;
    expect(virtualHearingForm).toMatchSnapshot();
  });
})
;
