import React from 'react';

import { logRoles } from '@testing-library/react';
import { HearingLinks } from 'app/hearings/components/details/HearingLinks';
import { anyUser, vsoUser } from 'test/data/user';
import { inProgressvirtualHearing } from 'test/data/virtualHearings';
import { virtualHearing, amaHearing } from 'test/data/hearings';
import { render, screen } from "@testing-library/react";
import VirtualHearingLink from
  'app/hearings/components/VirtualHearingLink';

const hearing = {
  scheduledForIsPast: false
};

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
    const {asFragment} = render(
      <HearingLinks
        hearing={hearing}
        wasVirtual
        user={anyUser}
        virtualHearing={inProgressvirtualHearing}
      />
    );

    expect(asFragment()).toMatchSnapshot();

    const elementsWithTestId = screen.queryByTestId("strong-element-test-id");
    expect(elementsWithTestId).toBeNull();

    const expired = screen.getAllByText("Expired");
    expect(expired.length).toEqual(2);
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
    expect(screen.getByRole("button", { name: /guest link/i })).toBeInTheDocument();
  })
});
