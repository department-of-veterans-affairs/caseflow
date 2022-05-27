import React from "react";

import { VSOHearingTypeConversionForm } from "app/hearings/components/VSOHearingTypeConversionForm";

import { mount } from "enzyme";
import { VSOAppellantSection } from "app/hearings/components/VirtualHearings/VSOAppellantSection";
import { VSORepresentativeSection } from "app/hearings/components/VirtualHearings/VSORepresentativeSection";
import { HearingEmail } from "app/hearings/components/details/HearingEmail";
import { getAppellantTitle } from "app/hearings/utils";

import COPY from "COPY";
import { templateSettings } from "lodash";

describe("VSOHearingTypeConversionForm", () => {
  test("Display claimant email on VSOHearingTypeConversionForm", () => {
    const vsoHearingTypeConversionForm = mount(
      <VSOHearingTypeConversionForm
        appeal={legacyAppealForTravelBoard}
        type="Virtual"
      />
    );

    expect(vsoHearingTypeConversionForm)
      .find(VSOAppellantSection)
      .toHaveEmail(true);
  });

  test("Display claimant timezone on VSOHearingTypeConversionForm", () => {
    const vsoHearingTypeConversionForm = mount(
      <VSOHearingTypeConversionForm
        appeal={legacyAppealForTravelBoard}
        type="Virtual"
      />
    );
    expect(vsoHearingTypeConversionForm)
      .find(VSORepresentativeSection)
      .toHaveEmail(true);
  });

  test("Display current user email on VSOHearingTypeConversionForm", () => {
    const vsoHearingTypeConversionForm = mount(
      <VSOHearingTypeConversionForm
        appeal={legacyAppealForTravelBoard}
        type="Virtual"
      />
    );
    expect(vsoHearingTypeConversionForm)
      .find(VSORepresentativeSection)
      .toHaveEmail(true);
  });

  test("Display current user time zone on VSOHearingTypeConversionForm", () => {
    const vsoHearingTypeConversionForm = mount(
      <VSOHearingTypeConversionForm
        appeal={legacyAppealForTravelBoard}
        type="Virtual"
      />
    );
    expect(vsoHearingTypeConversionForm)
      .find(VSORepresentativeSection)
      .toHaveTimeZone(true);
  });
});
