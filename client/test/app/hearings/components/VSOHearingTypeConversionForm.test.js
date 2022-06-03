import React from 'react';
import { render, screen, cleanup } from '@testing-library/react';

import { virtualAppeal } from 'test/data';
import { VSOHearingTypeConversionForm } from 'app/hearings/components/VSOHearingTypeConversionForm';

const renderVSOHearingTypeConversionForm = (appeal) => {
  return render(<VSOHearingTypeConversionForm appeal={appeal} type="Virtual" />);
};

beforeEach(() => {
  renderVSOHearingTypeConversionForm(virtualAppeal);
});

afterEach(() => {
  cleanup();
});

describe('VSOHearingTypeConversionForm', () => {
  test('Display claimant email on VSOHearingTypeConversionForm', () => {
    expect(screen.getByRole('textbox', { name: 'Veteran Email Required' }).value).toEqual(
      virtualAppeal.appellantEmail
    );
  });

  test('Display appellant timezone on VSOHearingTypeConversionForm', () => {
    expect(screen.getByRole('combobox', { name: 'Veteran Timezone Required' }).value).toBe(
      virtualAppeal.appellantTz
    );
  });

  test('Display current user email on VSOHearingTypeConversionForm', () => {
    expect(screen.getByRole('textbox', { name: 'POA/Representative Email Optional' }).value).toBe(
      virtualAppeal.currentUserEmail
    );
  });

  test('Display current user time zone on VSOHearingTypeConversionForm', () => {
    expect(screen.getByRole('combobox', { name: 'POA/Representative Timezone Required' }).value).toBe(
      virtualAppeal.currentUserTimezone
    );
  });
});
