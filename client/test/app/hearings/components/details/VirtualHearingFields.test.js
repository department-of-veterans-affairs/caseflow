import React from 'react';
import { render as rtlRender, screen } from '@testing-library/react';

// Component under test
import { VirtualHearingFields } from 'app/hearings/components/details/VirtualHearingFields';

// Test helpers and data
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import { anyUser, amaHearing, defaultHearing, virtualHearing } from 'test/data';

// Setup the spies
const updateSpy = jest.fn();

// Wrappers
function customRender(ui, { wrapper: Wrapper, wrapperProps, ...options }) {
  if (Wrapper) {
    ui = <Wrapper {...wrapperProps}>{ui}</Wrapper>;
  }
  return rtlRender(ui, options);
}

const Wrapper = ({ children, user, hearing, store }) => {
  const HearingDetails = hearingDetailsWrapper(user, hearing);
  return (
    <HearingDetails store={store}>
      {children}
    </HearingDetails>
  );
};

describe('VirtualHearingFields', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const { asFragment } = customRender(
      <VirtualHearingFields
        update={updateSpy}
        hearing={defaultHearing}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: { user: anyUser, hearing: amaHearing, store: detailsStore }
      }
    );

    // Assertions
    const virtualHearingFrom  = screen.queryByRole('heading', { name: /Virtual Hearing Links/i });
    expect(virtualHearingFrom).not.toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Shows only hearing links with no virtualHearing', () => {
    // Run the test
    const { asFragment, container } = customRender(
      <VirtualHearingFields
        update={updateSpy}
        hearing={amaHearing}
        virtualHearing={amaHearing.virtualHearing}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: { user: anyUser, hearing: amaHearing, store: detailsStore }
      }
    );

    // Assertions
    const virtualHearingFrom  = screen.getByRole('heading', { name: /Virtual Hearing Links/i });
    expect(virtualHearingFrom).toBeInTheDocument();

    // Test HearingLinks presence
    const guestLink = screen.getByText('Guest Link:');
    expect(guestLink).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Shows hearing details with virtualHearing', () => {
    // Run the test
    const { asFragment, container } = customRender(
      <VirtualHearingFields
        update={updateSpy}
        hearing={amaHearing}
        virtualHearing={virtualHearing.virtualHearing}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: { user: anyUser, hearing: amaHearing, store: detailsStore }
      }
    );

    const hearingMeetingType = amaHearing.judge.meetingType;

    // Assertions
    const virtualHearingFrom  = screen.getByRole('heading', { name: /Virtual Hearing Links/i });
    expect(virtualHearingFrom).toBeInTheDocument();

    // Test HearingLinks presence
    const guestLink = screen.getByText(/Guest Link:/);
    expect(guestLink).toBeInTheDocument();
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

    // expect(virtualHearingForm).toMatchSnapshot();
    expect(asFragment()).toMatchSnapshot();
  });
});
