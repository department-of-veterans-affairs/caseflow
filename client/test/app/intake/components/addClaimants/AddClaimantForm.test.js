import React from 'react';
import { screen, render } from '@testing-library/react';
import { axe } from 'jest-axe';

import { AddClaimantForm } from 'app/intake/components/addClaimant/AddClaimantForm';
import { FormProvider } from 'react-hook-form';
import { useAddClaimantForm } from '../../../../../app/intake/components/addClaimant/utils';

const FormWrapper = ({ children }) => {
  const methods = useAddClaimantForm();

  return <FormProvider {...methods}>{children}</FormProvider>;
};

describe('AddClaimantForm', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const onSubmit = jest.fn();

  const setup = (props = { onSubmit }) => {
    return render(<AddClaimantForm {...props} />, { wrapper: FormWrapper });
  };

  it('renders default state correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
