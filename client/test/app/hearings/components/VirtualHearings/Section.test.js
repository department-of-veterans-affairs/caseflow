import React from "react";
import { shallow } from "enzyme";
import { render, screen } from "@testing-library/react";

import { VirtualHearingSection } from "app/hearings/components/VirtualHearings/Section";

// Setup the test
const label = "Section Header";
const Tester = () => <div data-testid="tester-component" />;

describe("VirtualHearingSection", () => {
  test("Matches snapshot with default props", () => {
    // Run the test
    const { asFragment } = render(
      <VirtualHearingSection label={label}>
        <Tester />
      </VirtualHearingSection>
    );

    // Assertions
    const testerComponent = screen.getByTestId("tester-component");
    expect(testerComponent).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test("Returns nothing when hide prop is true", () => {
    // Run the test
    const { container } = render(
      <VirtualHearingSection label={label} hide>
        <Tester />
      </VirtualHearingSection>
    );

    const testerComponent = screen.queryByTestId('tester-component');

    // Assertions
    expect(testerComponent).not.toBeInTheDocument();
    expect(container.children.length).toBe(0);
    expect(container.firstChild).toBeNull();
    expect(container).toMatchSnapshot(`<div />`);
  });
});
