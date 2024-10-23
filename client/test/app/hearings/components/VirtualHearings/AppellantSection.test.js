import React from 'react';
import { render, screen} from '@testing-library/react';
import { AppellantSection } from 'app/hearings/components/VirtualHearings/AppellantSection';
import { virtualHearing, defaultHearing } from 'test/data/hearings';
import { HEARING_CONVERSION_TYPES } from 'app/hearings/constants';
import COPY from 'COPY';
import { sprintf } from 'sprintf-js';

const updateSpy = jest.fn();
const hearingDayDate = '2025-01-01';

const convertRegex = (str) => {
  return new RegExp(str, 'i');
}
const cityStateZip = `${defaultHearing.appellantCity}, ${defaultHearing.appellantState} ${defaultHearing.appellantZip}`;
const address = `${defaultHearing.appellantAddressLine1}`;
const emailTextbox = "POA/Representative Email (for these notifications only) Optional";
const veteranLabelEmail = /Veteran Email \(for these notifications only\)/i;
const appellantLabelEmail = /Appellant Email \(for these notifications only\)/i;
const veteranName = `${defaultHearing.veteranFirstName} ${defaultHearing.veteranLastName}`;
const appellantName = `${defaultHearing.appellantFirstName} ${defaultHearing.appellantLastName}`;

describe('Appellant', () => {
  test('Matches snapshot with default props', () => {
    const {asFragment} = render(
      <AppellantSection
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
      />
    );

    // Assertions
    expect(screen.getAllByText(convertRegex(veteranName)).length).toBe(2);
    expect(screen.getByText(convertRegex(address))).toBeInTheDocument();
    expect(screen.getByText(convertRegex(cityStateZip))).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'Veteran' })).toBeInTheDocument();
    expect(screen.getByRole('textbox', { name: 'Veteran Email (for these notifications only) Required' })).toBeInTheDocument();
    expect(screen.getByLabelText(veteranLabelEmail)).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Does not allow editing emails when read-only', () => {
    const {asFragment} = render(
      <AppellantSection
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
      <AppellantSection
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
    expect(screen.getByRole('textbox', { name: 'Veteran Email (for these notifications only) Required' })).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays email alert when email is null', () => {
    const appellantTitle = "Veteran";
    const {asFragment} = render(
      <AppellantSection
        appellantTitle={appellantTitle}
        virtualHearing={{ appellantEmail: null }}
        hearing={{ ...defaultHearing, appellantEmailAddress: null }}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
        readOnly
        showMissingEmailAlert
      />
    );

    // Assertions
    const alertMessage = sprintf(COPY.MISSING_EMAIL_ALERT_MESSAGE, appellantTitle);
    expect(screen.getByText(convertRegex(alertMessage))).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays email alert when email is undefined', () => {
    const appellantTitle = "Veteran";
    const {container, asFragment} = render(
      <AppellantSection
        appellantTitle={appellantTitle}
        // eslint-disable-next-line
        hearing={{ ...defaultHearing, appellantEmailAddress: undefined }}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
        readOnly
        showMissingEmailAlert
      />
    );

    // Assertions
    const alertMessage = sprintf(COPY.MISSING_EMAIL_ALERT_MESSAGE, appellantTitle);
    expect(screen.getByText(convertRegex(alertMessage))).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays appellant information when appellant is not veteran', () => {
    const {container, asFragment} = render(
      <AppellantSection
        appellantTitle="Appellant"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={
          {
            ...defaultHearing,
            appellantIsNotVeteran: true
          }
        }
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
      />
    );

    expect(screen.getByText(convertRegex("Appellant Name"))).toBeInTheDocument();
    expect(screen.getByText(convertRegex("Relation to Veteran"))).toBeInTheDocument();
    expect(screen.getByText(convertRegex("Appellant Mailing Address"))).toBeInTheDocument();
    expect(screen.getAllByText(convertRegex(appellantName)).length).toBe(2);
    expect(screen.getByText(convertRegex(defaultHearing.appellantRelationship))).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Does not display address when formFieldsOnly = true', () => {
    const {asFragment} = render(
      <AppellantSection
        formFieldsOnly
        appellantTitle="Appellant"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        hearingDayDate={hearingDayDate}
      />
    );

    expect(screen.queryByText(convertRegex(cityStateZip))).toBeNull();
    expect(screen.getByLabelText(appellantLabelEmail)).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });
});
