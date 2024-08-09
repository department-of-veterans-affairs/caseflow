import React from 'react';
import { render, screen, cleanup } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { virtualAppeal, scheduleHearingTask } from 'test/data';
import { HearingTypeConversionProvider } from '../../../../app/hearings/contexts/HearingTypeConversionContext';
import { VSOHearingTypeConversionForm } from 'app/hearings/components/VSOHearingTypeConversionForm';

const renderVSOHearingTypeConversionForm = (appeal) => {
  return render(
    <HearingTypeConversionProvider initialAppeal={appeal}>
      <VSOHearingTypeConversionForm
        appeal={appeal}
        task={scheduleHearingTask}
        type={appeal.type}
      />
    </HearingTypeConversionProvider>
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
    screen.getByText('Nairobi');
    const comboBoxes = screen.getAllByRole('combobox').filter((element) => element.id === 'appellant-tz');

    // const appellantTzDropdown = screen.getByRole('combobox', { name: 'Appellant Timezone Required' });
    const appellantTzDropdown = comboBoxes[0];

    userEvent.click(appellantTzDropdown);
    userEvent.click(screen.getByText('Guam'));

    expect(screen.findByText('Guam')).toBeTruthy();
    expect(screen.queryByText('Nairobi')).not.toBeInTheDocument();
  });

  test('Display current user email on VSOHearingTypeConversionForm', () => {
    expect(screen.getByText(virtualAppeal.currentUserEmail)).toBeTruthy();
  });

  test('Display current user time zone on VSOHearingTypeConversionForm', async () => {
    // Default representative timezone
    screen.getByText('Eastern Time (US & Canada)');

    // const representativeTzDropdown = screen.getByRole('combobox', { name: 'POA/Representative Timezone Required' });
    const comboBoxes = screen.getAllByRole('combobox').filter((element) => element.id === 'representative-tz');

    const representativeTzDropdown = comboBoxes[0];
    userEvent.click(representativeTzDropdown);
    userEvent.click(screen.getByText('Vienna'));

    expect(screen.getByText('Vienna')).toBeTruthy();
    expect(screen.queryByText('Eastern Time (US & Canada)')).not.toBeInTheDocument();
  });
});
