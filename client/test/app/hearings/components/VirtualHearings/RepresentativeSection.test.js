import React from 'react';
import { render, screen} from '@testing-library/react';

import { virtualHearing, defaultHearing } from 'test/data/hearings';
import { HEARING_CONVERSION_TYPES } from 'app/hearings/constants';
import { RepresentativeSection } from 'app/hearings/components/VirtualHearings/RepresentativeSection';
import { amaHearing } from 'test/data';
import { getAppellantTitle } from 'app/hearings/utils';

const updateSpy = jest.fn();
const hearingDayDate = '2025-01-01';

const convertRegex = (str) => {
  return new RegExp(str, 'i');
}
const cityStateZip = `${defaultHearing.representativeAddress.city}, ${defaultHearing.representativeAddress.state} ${defaultHearing.representativeAddress.zip}`;
const emailTextbox = "POA/Representative Email (for these notifications only) Optional";
const labelForEmail = /POA\/Representative Email \(for these notifications only\)/i;
const timeZoneSearch = "POA/Representative Timezone Optional";
const representative = defaultHearing.representative;
const amaRepresentative = amaHearing.representativeName;

describe('RepresentativeSection', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const {asFragment} = render(
      <RepresentativeSection
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
      />
    );

    // Assertions
    expect(screen.getByText(convertRegex(representative))).toBeInTheDocument();
    expect(screen.getByText(convertRegex(
      defaultHearing.representativeAddress.addressLine1))).toBeInTheDocument();
    expect(screen.getByText(convertRegex(cityStateZip))).toBeInTheDocument();
    expect(screen.getByLabelText(labelForEmail)).toBeInTheDocument();
    expect(screen.getByRole('textbox', { name: emailTextbox })).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Does not allow editing emails when read-only', () => {
    const {asFragment} = render(
      <RepresentativeSection
        readOnly
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
      />
    );

    // Assertions
    expect(screen.queryByRole('textbox', { name: emailTextbox })).toBeNull();
    expect(screen.getByText(/None/i)).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays timezone when showTimezoneField is passed as prop', () => {
    const {asFragment} = render(
      <RepresentativeSection
        showTimezoneField
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
      />
    );

    // Assertions
    expect(screen.getByRole('combobox', { name: timeZoneSearch })).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Shows Representative not present message when no representative', () => {
    const {asFragment} = render(
      <RepresentativeSection
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={{
          ...amaHearing,
          representative: null
        }}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
      />
    );

    // Assertions
    expect(screen.queryByText(convertRegex(cityStateZip))).toBeNull();
    expect(screen.getByLabelText(labelForEmail)).toBeInTheDocument();
    expect(screen.getByText(`The ${getAppellantTitle(amaHearing.appellantIsNotVeteran)} does not have a representative recorded in VBMS`)).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Shows Representative name when representative address blank', () => {
    const {asFragment} = render(
      <RepresentativeSection
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={{
          ...amaHearing,
          representativeAddress: null
        }}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
      />
    );

    // Assertions
    expect(screen.getByText(convertRegex(amaRepresentative))).toBeInTheDocument();
    expect(screen.queryByText(convertRegex(defaultHearing.representativeAddress.addressLine1))).not.toBeInTheDocument();
    expect(screen.queryByText(convertRegex(cityStateZip))).not.toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Does not display address when formFieldsOnly = true', () => {
    const {asFragment} = render(
      <RepresentativeSection
        formFieldsOnly
        appellantTitle="Appellant"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
      />
    );

    // Assertions
    expect(screen.getByText(convertRegex(representative))).toBeInTheDocument();
    expect(screen.queryByText(convertRegex(cityStateZip))).toBeNull();
    expect(screen.getByLabelText(labelForEmail)).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });
});
