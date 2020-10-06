import React from 'react';
import { mount } from 'enzyme';

import Alert from 'app/components/Alert';
import { AppellantSection } from 'app/hearings/components/VirtualHearings/AppellantSection';
import { virtualHearing, defaultHearing } from 'test/data/hearings';
import { HEARING_CONVERSION_TYPES } from 'app/hearings/constants';

import { AddressLine } from 'app/hearings/components/details/Address';
import { VirtualHearingEmail } from 'app/hearings/components/VirtualHearings/Emails';
import { Timezone } from 'app/hearings/components/VirtualHearings/Timezone';
import TextField from 'app/components/TextField';

const updateSpy = jest.fn();

describe('Appellant', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const appellantSection = mount(
      <AppellantSection
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
      />
    );

    // Assertions
    expect(appellantSection.find(AddressLine)).toHaveLength(1);
    expect(appellantSection.find(VirtualHearingEmail)).toHaveLength(1);
    expect(appellantSection.find(TextField)).toHaveLength(1);
    expect(appellantSection).toMatchSnapshot();
  });

  test('Does not allow editing emails when read-only', () => {
    // Run the test
    const appellantSection = mount(
      <AppellantSection
        readOnly
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
      />
    );

    // Ensure the emails are read-only
    expect(appellantSection.find(TextField)).toHaveLength(0);
    appellantSection.find(VirtualHearingEmail).map((node) => expect(node.prop('readOnly')).toEqual(true));
    expect(appellantSection).toMatchSnapshot();
  });

  test('Displays timezone when virtual', () => {
    // Run the test
    const appellantSection = mount(
      <AppellantSection
        virtual
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
      />
    );

    // Ensure the emails are read-only
    expect(appellantSection.find(Timezone)).toHaveLength(1);
    expect(appellantSection).toMatchSnapshot();
  });

  test('Displays email alert when email is null', () => {
    // Run the test
    const appellantSection = mount(
      <AppellantSection
        virtual
        appellantTitle="Veteran"
        virtualHearing={{ appellantEmail: null }}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        readOnly
        showMissingEmailAlert
      />
    );

    // Ensure the alert displays
    expect(appellantSection.find(Alert)).toHaveLength(1);
    expect(appellantSection).toMatchSnapshot();
  });

  test('Displays email alert when email is undefined', () => {
    // Run the test
    const appellantSection = mount(
      <AppellantSection
        virtual
        appellantTitle="Veteran"
        virtualHearing={{}}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
        readOnly
        showMissingEmailAlert
      />
    );

    // Ensure the alert displays
    expect(appellantSection.find(Alert)).toHaveLength(1);
    expect(appellantSection).toMatchSnapshot();
  });
});
