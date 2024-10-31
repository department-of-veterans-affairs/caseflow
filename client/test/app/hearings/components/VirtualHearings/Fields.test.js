import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';

import { EmailNotificationFields } from 'app/hearings/components/details/EmailNotificationFields';
import { defaultHearing as hearing } from 'test/data/hearings';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';

describe('Fields', () => {

  const expectations = async (container) => {
    // Emails
    const appellantEmailInput = screen.getByRole('textbox', { name: /Veteran Email/i });
    const poaRepEmailInput = screen.getByRole('textbox', { name: /POA\/Representative Email/i });
    expect(appellantEmailInput).toBeInTheDocument();
    expect(poaRepEmailInput).toBeInTheDocument();

    expect(appellantEmailInput).toHaveValue(hearing.appellantEmailAddress);
;
    const labelElement = appellantEmailInput.parentElement.previousElementSibling;
    let labelText = labelElement.textContent.trim();
    labelText = labelText.replace('Optional', '').trim();
    expect(labelText).toEqual('Veteran Email');

    expect(poaRepEmailInput).toHaveValue(hearing.representativeEmailAddress);

    // // Timezones
    const veteranTimezoneInput = screen.getByRole('combobox', { name: /Veteran Timezone/i });
    const poaRepTimezoneInput = screen.getByRole('combobox', { name: /POA\/Representative Timezone/i });
    expect(veteranTimezoneInput).toBeInTheDocument();
    expect(poaRepTimezoneInput).toBeInTheDocument();

    await waitFor(() => {
      expect(veteranTimezoneInput).toHaveValue(hearing.appellantTz);
      expect(poaRepTimezoneInput).toHaveValue(hearing.representativeTz);
    });

    // // Other components
    const dividerElement = container.querySelector('.cf-help-divider');
    console.log("DIVIDER ELEMENT!!", dividerElement);
    expect(dividerElement).toBeInTheDocument();
  };

  test('Display timezone and divider for Central', () => {
    // Run the test
    const { container } = render(
      <EmailNotificationFields
        appellantTitle="Veteran"
        time={HEARING_TIME_OPTIONS[0].value}
        requestType="Central"
        hearing={hearing}
      />
    );

    expectations(container);
    expect(container).toMatchSnapshot();
  });

  test('Display timezone and divider for Video', () => {
    // Run the test
    const { container } = render(
      <EmailNotificationFields
        appellantTitle="Veteran"
        time={HEARING_TIME_OPTIONS[0].value}
        requestType="Video"
        hearing={hearing}
      />
    );

    expectations(container);
    expect(container).toMatchSnapshot();
  });
});
