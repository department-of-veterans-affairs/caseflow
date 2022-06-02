import React from "react";

import { VSOHearingTypeConversionForm } from "app/hearings/components/VSOHearingTypeConversionForm";

import { mount } from "enzyme";
import { virtualAppeal, appealData } from "test/data";

describe("VSOHearingTypeConversionForm", () => {
  test("Display claimant email on VSOHearingTypeConversionForm", () => {
    const appeal = {
      appealData,
      appellantEmailAddress: { ...virtualAppeal },
    };

    const vsoHearingTypeConversionForm = mount(
      <VSOHearingTypeConversionForm appeal={appeal} type="Virtual" />
    );

    expect(vsoHearingTypeConversionForm.appellantEmailAddress).toEqual(
      "susan@gmail.com"
    );
  });

  test("Display claimant timezone on VSOHearingTypeConversionForm", () => {
    const appeal = {
      appealData,
      appellantTz: { ...virtualAppeal },
    };

    const vsoHearingTypeConversionForm = mount(
      <VSOHearingTypeConversionForm appeal={appeal} type="Virtual" />
    );

    expect(vsoHearingTypeConversionForm.appellantTz).toEqual(
      "America/New_York"
    );
  });

  test("Display current user email on VSOHearingTypeConversionForm", () => {
    const appeal = {
      appealData,
      currentUserEmail: { ...virtualAppeal },
    };

    const vsoHearingTypeConversionForm = mount(
      <VSOHearingTypeConversionForm appeal={appeal} type="Virtual" />
    );

    expect(vsoHearingTypeConversionForm.currentUserEmail).toEqual(
      "tom@brady.com"
    );
  });

  test("Display current user time zone on VSOHearingTypeConversionForm", () => {
    const appeal = {
      appealData,
      currentUserTimezone: { ...virtualAppeal },
    };

    const vsoHearingTypeConversionForm = mount(
      <VSOHearingTypeConversionForm appeal={appeal} type="Virtual" />
    );

    expect(vsoHearingTypeConversionForm.currentUserTimezone).toEqual(
      "America/New_York"
    );
  });
});
