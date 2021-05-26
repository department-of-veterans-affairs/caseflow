import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';

import ApiUtil from 'app/util/ApiUtil';
import { AddHearingDay } from 'app/hearings/components/AddHearingDay';
import { queueWrapper as Wrapper } from 'test/data/stores/queueStore';
import { REQUEST_TYPE_OPTIONS } from 'app/hearings/constants';

import { roList } from 'test/data/regional-offices';

// Mock the Reducer actions
jest.mock('app/queue/uiReducer/uiActions');

// Setup the test variables
const date = '2021-05-24';

// Set the spies
let getSpy;
const changeHearingDaySpy = jest.fn();
const submitSpy = jest.fn();
const cancelSpy = jest.fn();
const ro = roList[3].value;
const historySpy = {
  push: jest.fn()
};

const storeArgs = {
  components: {
    dropdowns: {
      regionalOffices: {
        isFetching: false,
        options: roList
      }
    }
  }
};

describe('AddHearingDay', () => {
  beforeEach(() => {
    // Judge Dropdown
    getSpy = jest.spyOn(ApiUtil, 'get').
      mockImplementationOnce(() => new Promise((resolve) => resolve({ body: { judges: [] } })));

    // Coordinator Dropdown
    getSpy = jest.spyOn(ApiUtil, 'get').
      mockImplementationOnce(() => new Promise((resolve) => resolve({ body: { coordinators: [] } })));

  });

  const setup = (props) => {
    const component = render(
      <Wrapper {...storeArgs}>
        <AddHearingDay {...props} history={historySpy} onSelectedHearingDayChange={changeHearingDaySpy} />
      </Wrapper>
    );

    const docketDate = component.getByLabelText('Docket Date');
    const docketType = screen.getByRole('combobox', { name: 'Docket Type' });
    const roomRequired = screen.getByRole('checkbox', { name: 'roomRequired' });
    const notes = screen.getByRole('textbox', { name: 'Notes Optional' });

    // Hidden Dropdowns
    const roDropdown = screen.queryByText('Regional Office (RO)');
    const vljDropdown = screen.queryByText('VLJ');
    const coordinatorDropdown = screen.queryByText('Hearing Coordinator');
    const slotCount = screen.queryByText('Number of Time Slots');
    const slotLength = screen.queryByText('Length of Time Slots');
    const slotStartTime = screen.queryByText('Start Time of Slots');
    const slotPreview = screen.queryByText('Preview Time Slots');

    const cancelButton = screen.getByRole('button', { name: 'Cancel' });
    const submitButton = screen.getByRole('button', { name: 'Add Hearing Day' });

    return {
      slotCount,
      slotLength,
      roDropdown,
      vljDropdown,
      slotStartTime,
      slotPreview,
      coordinatorDropdown,
      component,
      cancelButton,
      submitButton,
      docketDate,
      docketType,
      roomRequired,
      notes,
    };
  };

  test('Matches snapshot with default props', () => {
    // Render the address component
    const addHearingDay = setup();

    // Form components
    expect(screen.getByRole('heading', { name: 'Add a Hearing Day' })).toBeInTheDocument();
    expect(addHearingDay.docketDate.value).toBe('');
    expect(addHearingDay.docketType.value).toBe('');
    expect(addHearingDay.roomRequired.checked).toBe(false);
    expect(addHearingDay.notes.value).toBe('');

    // Hidden dropdowns
    expect(addHearingDay.roDropdown).toBeNull();
    expect(addHearingDay.vljDropdown).toBeNull();
    expect(addHearingDay.coordinatorDropdown).toBeNull();
    expect(addHearingDay.slotCount).toBeNull();
    expect(addHearingDay.slotLength).toBeNull();
    expect(addHearingDay.slotStartTime).toBeNull();
    expect(addHearingDay.slotPreview).toBeNull();

    // Form controls
    expect(addHearingDay.cancelButton).toBeInTheDocument();
    expect(addHearingDay.submitButton).toBeInTheDocument();

    // Container snapshot assertion
    expect(addHearingDay.component.container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { component: { container } } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  test('Displays Hearing Day fields when docket type set', async () => {
    // Render the address component with a Video request type
    const addHearingDay = setup({ requestType: REQUEST_TYPE_OPTIONS[0], selectedRegionalOffice: ro });

    // Set the form fields
    await userEvent.type(addHearingDay.docketDate, date);
    expect(addHearingDay.docketDate.value).toBe(date);

    await userEvent.type(addHearingDay.roDropdown, ro.label);
    expect(screen.getByRole('combobox', { name: 'Regional Office (RO)' }).value).toBe(ro.label);

    await userEvent.type(addHearingDay.docketType, REQUEST_TYPE_OPTIONS[0].label);
    expect(addHearingDay.docketType.value).toBe(REQUEST_TYPE_OPTIONS[0].label);

    // Ensure that the dropdowns are visible but values undefined
    expect(addHearingDay.vljDropdown.value).toBeUndefined();
    expect(addHearingDay.coordinatorDropdown.value).toBeUndefined();

    // Ensure the time slot components do not display for video
    expect(addHearingDay.slotCount).toBeNull();
    expect(addHearingDay.slotLength).toBeNull();
    expect(addHearingDay.slotStartTime).toBeNull();
    expect(addHearingDay.slotPreview).toBeNull();

    // Container snapshot assertion
    expect(addHearingDay.component).toMatchSnapshot();
  });

  test('Displays Time Slot controls when docket type is Virtual', async () => {
    // Render the address component with a Virtual request type
    const addHearingDay = setup({ requestType: REQUEST_TYPE_OPTIONS[2], selectedRegionalOffice: ro });

    // Set the form fields
    await userEvent.type(addHearingDay.docketDate, date);
    expect(addHearingDay.docketDate.value).toBe(date);

    await userEvent.type(addHearingDay.roDropdown, ro.label);
    expect(screen.getByRole('combobox', { name: 'Regional Office (RO)' }).value).toBe(ro.label);

    await userEvent.type(addHearingDay.docketType, REQUEST_TYPE_OPTIONS[2].label);
    expect(addHearingDay.docketType.value).toBe(REQUEST_TYPE_OPTIONS[2].label);

    // Ensure that the dropdowns are visible but values undefined
    expect(addHearingDay.vljDropdown.value).toBeUndefined();
    expect(addHearingDay.coordinatorDropdown.value).toBeUndefined();

    // Ensure the time slot components display for virtual
    expect(addHearingDay.slotCount.value).toBeUndefined();
    expect(addHearingDay.slotLength.value).toBeUndefined();
    expect(addHearingDay.slotStartTime.value).toBeUndefined();
    expect(addHearingDay.slotPreview).not.toBeNull();

    // Container snapshot assertion
    expect(addHearingDay.component).toMatchSnapshot();
  });

  test('Can Cancel the form', async () => {
    // Render the address component with a Virtual request type
    const addHearingDay = setup();

    // Click the cancel button
    await userEvent.click(screen.getByRole('button', { name: 'Cancel' }));

    // Check the click event
    expect(historySpy.push).toHaveBeenCalledWith('/schedule');

    // Container snapshot assertion
    expect(addHearingDay.component).toMatchSnapshot();
  });

});
