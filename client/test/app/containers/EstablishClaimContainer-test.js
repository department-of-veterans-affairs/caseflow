import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";

import { WrappingComponent } from "../establishClaim/WrappingComponent";
import EstablishClaimContainer from "../../../app/containers/EstablishClaimPage/EstablishClaimContainer";

describe("EstablishClaimContainer", () => {
  const setup = () => {
    render(<EstablishClaimContainer page="TestPage" otherProp="foo" />, {
      wrapper: WrappingComponent,
    });
  };

  describe("sub-page", () => {
    it("renders", () => {
      setup();
      expect(screen.getByText("Test Page")).toBeInTheDocument();
    });
  });

  describe("renders alerts", () => {
    it("hides alert if none in state", () => {
      setup();
      expect(screen.queryByRole("alert")).not.toBeInTheDocument();
    });

    it("shows alert if alert in state", () => {
      setup();
      const alert = screen.queryByRole("alert");
      const handleAlert = screen.getByTestId("test-page-handle-alert");

      expect(alert).not.toBeInTheDocument();
      fireEvent.click(handleAlert);
      expect(screen.getByRole("alert")).toBeInTheDocument();
    });

    it("clears alert when triggered", () => {
      setup();
      const handleAlert = screen.getByTestId("test-page-handle-alert");
      const handleAlertClear = screen.getByTestId("test-page-handle-alert-clear");

      fireEvent.click(handleAlert);
      expect(screen.getByRole("alert")).toBeInTheDocument();
      fireEvent.click(handleAlertClear);
      expect(screen.queryByRole("alert")).not.toBeInTheDocument();
    });
  });
});
