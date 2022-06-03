import React from "react";

import { VSOHearingTypeConversionForm } from "app/hearings/components/VSOHearingTypeConversionForm";

import { mount } from "enzyme";
import { virtualAppeal, appealData } from "test/data";

const mountVSOHearingTypeConversionForm = () => {
  return <VSOHearingTypeConversionForm appeal={virtualAppeal} type="Virtual" />
}

describe("VSOHearingTypeConversionForm", () => {
  test("Display claimant email on VSOHearingTypeConversionForm", () => {

    const vsoHearingTypeConversionForm = mountVSOHearingTypeConversionForm();

    expect(vsoHearingTypeConversionForm.appellantEmailAddress).toEqual(
      "susan@gmail.com"
    );
  });

  test("Display claimant timezone on VSOHearingTypeConversionForm", () => {

    const vsoHearingTypeConversionForm = mountVSOHearingTypeConversionForm();

    expect(vsoHearingTypeConversionForm.appellantTz).toEqual(
      "America/New_York"
    );
  });

  test("Display current user email on VSOHearingTypeConversionForm", () => {

    const vsoHearingTypeConversionForm = mountVSOHearingTypeConversionForm();

    expect(vsoHearingTypeConversionForm.currentUserEmail).toEqual(
      "tom@brady.com"
    );
  });

  test("Display current user time zone on VSOHearingTypeConversionForm", () => {

    const vsoHearingTypeConversionForm = mountVSOHearingTypeConversionForm();

    expect(vsoHearingTypeConversionForm.currentUserTimezone).toEqual(
      "America/New_York"
    );
  });
});
