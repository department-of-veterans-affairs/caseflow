import React from 'react';
import { render, screen } from '@testing-library/react';

import { virtualAppeal } from 'test/data';
import { VSOHearingTypeConversionForm } from 'app/hearings/components/VSOHearingTypeConversionForm';

const renderVSOHearingTypeConversionForm = (appeal) => {
  return render(<VSOHearingTypeConversionForm appeal={appeal} type="Virtual" />);
};


describe('VSOHearingTypeConversionForm', () => {
  renderVSOHearingTypeConversionForm(virtualAppeal);

  test('Display claimant email on VSOHearingTypeConversionForm', () => {
    expect(true).toEqual(
      virtualAppeal.appellantEmail
    );
  });

  test('Display appellant timezone on VSOHearingTypeConversionForm', () => {
    expect(true).toEqual(
      virtualAppeal.appellantTz
    );
  });

  test('Display POA email on VSOHearingTypeConversionForm', () => {
    expect(true).toEqual(
      virtualAppeal.representativeEmail
    );
  });

  test('Display POA time zone on VSOHearingTypeConversionForm', () => {
    expect(true).toEqual(
      virtualAppeal.currentUserEmail
    );
  });
});
