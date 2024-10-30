import React from 'react';
import { shallow, mount } from 'enzyme';

import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import SearchableDropdown from 'app/components/SearchableDropdown';
import {
  CENTRAL_OFFICE_HEARING_LABEL,
  VIDEO_HEARING_LABEL,
  VIRTUAL_HEARING_LABEL
} from 'app/hearings/constants';
import Select from 'react-select';

// Set the default options
const centralOpts = [
  {
    label: CENTRAL_OFFICE_HEARING_LABEL,
    value: false
  },
  {
    label: VIRTUAL_HEARING_LABEL,
    value: true
  }
];

const videoOpts = [
  {
    label: VIDEO_HEARING_LABEL,
    value: false
  },
  centralOpts[1]
];

// Create the method spies
const onChange = jest.fn();

describe('HearingTypeDropdown', () => {
  test('Matches snapshot with default props', () => {
    // Render the address component
    const hearingType = shallow(
      <HearingTypeDropdown
        dropdownOptions={centralOpts}
        currentOption={centralOpts[0]}
        onChange={onChange}
        readOnly={false}
      />
    );

    // Assertions
    expect(hearingType.find(SearchableDropdown)).toHaveLength(1);
    expect(hearingType.prop('label')).toEqual('Hearing Type');
    expect(hearingType.prop('options')).toEqual(centralOpts);
    expect(hearingType.prop('value')).toEqual(centralOpts[0]);
    expect(hearingType).toMatchSnapshot();
  });

  test('Can change from central office hearing', () => {
    // Render the address component
    const hearingType = mount(
      <HearingTypeDropdown
        dropdownOptions={centralOpts}
        currentOption={centralOpts[0]}
        onChange={onChange}
      />
    );
    const dropdown = hearingType.find(SearchableDropdown);

    // Initial state
    expect(hearingType.find(Select).prop('value')).toEqual(centralOpts[0]);

    // Open the menu
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    expect(hearingType.find('MenuList')).toHaveLength(1);

    // Change the value
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });

    // New state
    expect(hearingType.find(Select).prop('value')).toEqual(centralOpts[1]);
    expect(onChange).toHaveBeenCalled();
    expect(hearingType).toMatchSnapshot();
  });

  test('Can change from video hearing', () => {
    // Render the address component
    const hearingType = mount(
      <HearingTypeDropdown
        dropdownOptions={videoOpts}
        currentOption={videoOpts[0]}
        onChange={onChange}
      />
    );
    const dropdown = hearingType.find(SearchableDropdown);

    // Initial state
    expect(hearingType.find(Select).prop('value')).toEqual(videoOpts[0]);

    // Open the menu
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    expect(hearingType.find('MenuList')).toHaveLength(1);

    // Change the value
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });

    // New state
    expect(hearingType.find(Select).prop('value')).toEqual(videoOpts[1]);
    expect(onChange).toHaveBeenCalled();
    expect(hearingType).toMatchSnapshot();
  });

  test('Can change from virtual hearing to central', () => {
    // Render the address component
    const hearingType = mount(
      <HearingTypeDropdown
        dropdownOptions={centralOpts}
        currentOption={centralOpts[1]}
        onChange={onChange}
      />
    );
    const dropdown = hearingType.find(SearchableDropdown);

    // Initial state
    expect(hearingType.find(Select).prop('value')).toEqual(centralOpts[1]);

    // Open the menu
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    expect(hearingType.find('MenuList')).toHaveLength(1);

    // Change the value
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });

    // New state
    expect(hearingType.find(Select).prop('value')).toEqual(centralOpts[0]);
    expect(onChange).toHaveBeenCalled();
    expect(hearingType).toMatchSnapshot();
  });

  test('Can change from virtual hearing to video', () => {
    // Render the address component
    const hearingType = mount(
      <HearingTypeDropdown
        dropdownOptions={videoOpts}
        currentOption={videoOpts[1]}
        onChange={onChange}
      />
    );
    const dropdown = hearingType.find(SearchableDropdown);

    // Initial state
    expect(hearingType.find(Select).prop('value')).toEqual(videoOpts[1]);

    // Open the menu
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    expect(hearingType.find('MenuList')).toHaveLength(1);

    // Change the value
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });

    // New state
    expect(hearingType.find(Select).prop('value')).toEqual(videoOpts[0]);
    expect(onChange).toHaveBeenCalled();
    expect(hearingType).toMatchSnapshot();
  });
})
;
