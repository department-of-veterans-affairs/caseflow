import React from 'react';
import { shallow } from 'enzyme';

import { VirtualHearingSection } from 'app/hearings/components/VirtualHearings/Section';

// Setup the test
const label = 'Section Header';
const Tester = () => <div />;

describe('VirtualHearingSection', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const section = shallow(<VirtualHearingSection label={label} ><Tester /></VirtualHearingSection>);

    // Assertions
    expect(section.find(Tester)).toHaveLength(1);
    expect(section).toMatchSnapshot();

  });

  test('Returns nothing when hide prop is true', () => {
    // Run the test
    const section = shallow(<VirtualHearingSection label={label} hide ><Tester /></VirtualHearingSection>);

    // Assertions
    expect(section.find(Tester)).toHaveLength(0);
    expect(section.children()).toHaveLength(0);
    expect(section).toEqual({});
    expect(section).toMatchSnapshot();

  });
})
;
