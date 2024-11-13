import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { WrappingComponent } from "../establishClaim/WrappingComponent";
import EstablishClaimContainer from "../../../app/containers/EstablishClaimPage/EstablishClaimContainer";

describe("EstablishClaimContainer", () => {
  const setup = () => {
    return render(<EstablishClaimContainer page="TestPage" otherProp="foo" />, {
      wrapper: WrappingComponent,
    });
  };

  describe("sub-page", () => {
    it("renders", () => {
      setup();
      expect(screen.getByText("Test Page")).toBeInTheDocument();
      const subPageElement = document.querySelector('.sub-page');
      expect(subPageElement).toBeInTheDocument();
    });
  });

  describe("renders alerts", () => {
    it("hides alert if none in state", () => {
      setup();
      expect(screen.queryByRole("alert")).not.toBeInTheDocument();
    });

    it("shows alert if alert in state", () => {
      const {container} = setup();

      const alert = screen.queryByRole("alert");
      const handleAlert = container.querySelector('.handleAlert');

      fireEvent.click(handleAlert);
      expect(alert).not.toBeInTheDocument();
      expect(screen.getByRole("alert")).toBeInTheDocument();
    });

    it("clears alert when triggered", () => {
      const { container } =  setup();
      const handleAlert = container.querySelector('.handleAlert');
      const handleAlertClear = container.querySelector('.handleAlertClear');

      fireEvent.click(handleAlert);
      expect(screen.getByRole("alert")).toBeInTheDocument();

      fireEvent.click(handleAlertClear);
      expect(screen.queryByRole("alert")).not.toBeInTheDocument();
    });
  });
});
