import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import {
  CENTRAL_OFFICE_HEARING_LABEL,
  VIDEO_HEARING_LABEL,
  VIRTUAL_HEARING_LABEL
} from 'app/hearings/constants';

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
    const { asFragment, container } = render(
      <HearingTypeDropdown
        dropdownOptions={centralOpts}
        currentOption={centralOpts[0]}
        onChange={onChange}
        readOnly={false}
      />
    );

    // Assertions
    const hearingTypeInput = screen.getByRole('combobox', { name: /hearing type/i });
    expect(hearingTypeInput).toBeInTheDocument();

    const hearingTypeLabel = screen.getByLabelText(/hearing type/i);
    expect(hearingTypeLabel).toBeInTheDocument();;

    expect(screen.getByText(centralOpts[0].label)).toBeInTheDocument();

    userEvent.click(hearingTypeInput);
    userEvent.type(hearingTypeInput, `${centralOpts[1].label}{enter}`);
    expect(screen.getByText(centralOpts[1].label)).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Can change from central office hearing', () => {
    // Render the address component
    const { asFragment } = render(
      <HearingTypeDropdown
        dropdownOptions={centralOpts}
        currentOption={centralOpts[0]}
        onChange={onChange}
      />
    );

    // Assertions
    expect(screen.getByRole('combobox', { name: /hearing type/i })).toBeInTheDocument();

    // Initial state
    expect(screen.getByText(centralOpts[0].label)).toBeInTheDocument();

    // Open the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown', keyCode: 40 });
    expect(screen.queryAllByRole('listbox')).toHaveLength(1);

    // Change the value
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'Enter' });

    // New state
    expect(screen.getByText(centralOpts[1].label.toString())).toBeInTheDocument();
    expect(onChange).toHaveBeenCalled();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Can change from video hearing', () => {
    // Render the address component
    const { asFragment } = render(
      <HearingTypeDropdown
        dropdownOptions={videoOpts}
        currentOption={videoOpts[0]}
        onChange={onChange}
      />
    );

    // Assertions
    expect(screen.getByRole('combobox', { name: /hearing type/i })).toBeInTheDocument();

    // Initial state
    expect(screen.getByText(videoOpts[0].label)).toBeInTheDocument();

    // Open the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    expect(screen.queryAllByRole('listbox')).toHaveLength(1);

    // Change the value
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'Enter' });

    // New state
    expect(screen.getByText(videoOpts[1].label.toString())).toBeInTheDocument();
    expect(onChange).toHaveBeenCalled();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Can change from virtual hearing to central', () => {
    // Render the address component
    const { asFragment } = render(
      <HearingTypeDropdown
        dropdownOptions={centralOpts}
        currentOption={centralOpts[1]}
        onChange={onChange}
      />
    );

    // Assertions
    expect(screen.getByRole('combobox', { name: /hearing type/i })).toBeInTheDocument();

    // Initial state
    expect(screen.getByText(centralOpts[1].label)).toBeInTheDocument();

    // Open the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    expect(screen.queryAllByRole('listbox')).toHaveLength(1);

    // Change the value
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'Enter' });

    // New state
    expect(screen.getByText(centralOpts[0].label.toString())).toBeInTheDocument();
    expect(onChange).toHaveBeenCalled();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Can change from virtual hearing to video', () => {
    // Render the address component
    const { asFragment } = render(
      <HearingTypeDropdown
        dropdownOptions={videoOpts}
        currentOption={videoOpts[1]}
        onChange={onChange}
      />
    );
    // Assertions
    expect(screen.getByRole('combobox', { name: /hearing type/i })).toBeInTheDocument();

    // Initial state
    expect(screen.getByText(videoOpts[1].label)).toBeInTheDocument();

    // Open the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    expect(screen.queryAllByRole('listbox')).toHaveLength(1);

    // Change the value
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'Enter' });

    // New state
    expect(screen.getByText(videoOpts[0].label.toString())).toBeInTheDocument();
    expect(onChange).toHaveBeenCalled();
    expect(asFragment()).toMatchSnapshot();
  });
});
