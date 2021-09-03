import React from 'react';
import { mount } from 'enzyme';

import { virtualHearing, defaultHearing } from 'test/data/hearings';
import { HEARING_CONVERSION_TYPES } from 'app/hearings/constants';
import { RepresentativeSection } from 'app/hearings/components/VirtualHearings/RepresentativeSection';
import { amaHearing } from 'test/data';
import { VirtualHearingSection } from 'app/hearings/components/VirtualHearings/Section';
import { AddressLine } from 'app/hearings/components/details/Address';
import { VirtualHearingEmail } from 'app/hearings/components/VirtualHearings/Emails';
import { Timezone } from 'app/hearings/components/VirtualHearings/Timezone';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';
import { getAppellantTitle } from 'app/hearings/utils';
import TextField from 'app/components/TextField';

const updateSpy = jest.fn();

describe('RepresentativeSection', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const representativeSection = mount(
      <RepresentativeSection
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
      />
    );

    // Assertions
    expect(representativeSection.find(AddressLine)).toHaveLength(1);
    expect(representativeSection.find(VirtualHearingEmail)).toHaveLength(1);
    expect(representativeSection.find(TextField)).toHaveLength(1);
    expect(representativeSection).toMatchSnapshot();
  });

  test('Does not allow editing emails when read-only', () => {
    // Run the test
    const representativeSection = mount(
      <RepresentativeSection
        readOnly
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
      />
    );

    // Ensure the emails are read-only
    expect(representativeSection.find(TextField)).toHaveLength(0);
    representativeSection.find(VirtualHearingEmail).map((node) => expect(node.prop('readOnly')).toEqual(true));
    expect(representativeSection).toMatchSnapshot();
  });

  test('Displays timezone when showTimezoneField is passed as prop', () => {
    // Run the test
    const representativeSection = mount(
      <RepresentativeSection
        showTimezoneField
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
      />
    );

    // Ensure the emails are read-only
    expect(representativeSection.find(Timezone)).toHaveLength(1);
    expect(representativeSection).toMatchSnapshot();
  });

  test('Shows Representative not present message when no representative', () => {
    const representativeSection = mount(
      <RepresentativeSection
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={{
          ...amaHearing,
          representative: null
        }}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
      />
    );

    // Assertions
    expect(representativeSection.find(AddressLine)).toHaveLength(0);
    expect(representativeSection.find(VirtualHearingEmail)).toHaveLength(1);
    expect(representativeSection.find(VirtualHearingSection).first().
      find(ReadOnly).
      prop('text')).toEqual(
      `The ${getAppellantTitle(amaHearing.appellantIsNotVeteran)} does not have a representative recorded in VBMS`
    );
    expect(representativeSection).toMatchSnapshot();
  });

  test('Shows Representative name when representative address blank', () => {
    const representativeSection = mount(
      <RepresentativeSection
        appellantTitle="Veteran"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={{
          ...amaHearing,
          representativeAddress: null
        }}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
      />
    );

    // Assertions
    expect(representativeSection.find(AddressLine)).toHaveLength(1);
    expect(representativeSection.find(VirtualHearingEmail)).toHaveLength(1);
    expect(representativeSection.find(AddressLine).first().
      text()).toMatch(amaHearing.representativeName);
    expect(representativeSection).toMatchSnapshot();
  });

  test('Does not display address when formFieldsOnly = true', () => {
    const representativeSection = mount(
      <RepresentativeSection
        formFieldsOnly
        appellantTitle="Appellant"
        virtualHearing={virtualHearing.virtualHearing}
        hearing={defaultHearing}
        type={HEARING_CONVERSION_TYPES[0]}
        update={updateSpy}
      />
    );

    expect(representativeSection.find(ReadOnly)).toHaveLength(1);
    expect(representativeSection.find(AddressLine)).toHaveLength(0);
    expect(representativeSection.find(VirtualHearingEmail)).toHaveLength(1);
    expect(representativeSection).toMatchSnapshot();
  });
});
