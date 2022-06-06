import React from 'react';
import { render, screen, cleanup } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { virtualAppeal, scheduleHearingTask } from 'test/data';
import { VSOHearingTypeConversionForm } from 'app/hearings/components/VSOHearingTypeConversionForm';

const renderVSOHearingTypeConversionForm = (appeal) => {
  return render(
    <VSOHearingTypeConversionForm
      appeal={appeal}
      task={scheduleHearingTask}
      type={appeal.type}
      update={jest.fn()}
    />
  );
};

beforeEach(() => {
  renderVSOHearingTypeConversionForm(virtualAppeal);
});

afterEach(() => {
  cleanup();
});

describe('VSOHearingTypeConversionForm', () => {
  test('Display claimant email on VSOHearingTypeConversionForm', () => {
    screen.getByText('Appellant Email');

    expect(
      screen.getByRole('textbox', { name: 'Appellant Email Required' }).value
    ).toBe(virtualAppeal.appellantEmailAddress);
  });

  test('Display appellant timezone on VSOHearingTypeConversionForm', async () => {
    // Default appellant timezone
    screen.getByText('Eastern Time (US & Canada)');

    const appellantTzDropdown = screen.getByRole('combobox', { name: 'Appellant Timezone Required' });

    userEvent.click(appellantTzDropdown);
    userEvent.click(screen.getByText('Guam'));

    expect(screen.findByText('Guam')).toBeTruthy();
  });

  test('Display current user email on VSOHearingTypeConversionForm', () => {
    expect(
      screen.getByRole('textbox', { name: 'POA/Representative Email Optional' }).
        value
    ).toBe(virtualAppeal.currentUserEmail);
  });

  test('Display current user time zone on VSOHearingTypeConversionForm', async () => {
    // Default representative timezone
    screen.getByText('Central Time (US & Canada)');

    const representativeTzDropdown = screen.getByRole('combobox', { name: 'POA/Representative Timezone Required' });

    userEvent.click(representativeTzDropdown);
    userEvent.click(screen.getByText('Vienna'));

    expect(screen.getByText('Vienna')).toBeTruthy();
  });
});
