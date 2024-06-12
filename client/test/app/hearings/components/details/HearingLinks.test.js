import React from "react";

import { HearingLinks } from "app/hearings/components/details/HearingLinks";
import { anyUser, vsoUser } from "test/data/user";
import { inProgressvirtualHearing } from "test/data/virtualHearings";
import { virtualHearing, amaHearing } from "test/data/hearings";
import { render, screen } from "@testing-library/react";
import VirtualHearingLink from "app/hearings/components/VirtualHearingLink";

const hearing = {
  scheduledForIsPast: false,
};

describe("HearingLinks", () => {
  test("Matches snapshot with default props when passed in", () => {
    render(<HearingLinks />);

    const virtualHearingLink = screen.queryByTestId("strong-element-test-id");
    expect(virtualHearingLink).not.toBeInTheDocument();
  });

  test("Matches snapshot when hearing is virtual and in progress", () => {
    render(<HearingLinks hearing={hearing} isVirtual user={anyUser} virtualHearing={inProgressvirtualHearing} />);

    const joinHearing = screen.getByText("Join Virtual Hearing");
    const startHearing = screen.getByText("Start Virtual Hearing");
    const virtualHearingLink = screen.getAllByTestId("strong-element-test-id");

    expect(virtualHearingLink).toHaveLength(2);
    expect(joinHearing).toBeInTheDocument();
    expect(startHearing).toBeInTheDocument();
  });

  test("Matches snapshot when hearing was virtual and occurred", () => {
    render(<HearingLinks hearing={hearing} wasVirtual user={anyUser} virtualHearing={inProgressvirtualHearing} />);

    const virtualHearingLink = screen.queryByTestId("strong-element-test-id");
    const expired = screen.getAllByText("Expired");

    expect(virtualHearingLink).not.toBeInTheDocument();
    expect(expired).toHaveLength(2);
  });

  test("Only displays Guest Link when user is not a host", () => {
    render(
      <HearingLinks hearing={amaHearing} isVirtual user={vsoUser} virtualHearing={virtualHearing.virtualHearing} />
    );

    const virtualHearingLink = screen.queryByTestId("strong-element-test-id");
    expect(virtualHearingLink).toBeInTheDocument();
    // Ensure it's the guest link
    expect(screen.getByRole("button", { name: /guest link/i })).toBeInTheDocument();
  });
});
