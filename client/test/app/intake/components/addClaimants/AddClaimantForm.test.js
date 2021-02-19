import React from 'react';
import { screen, render, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import { axe } from 'jest-axe';
import { FormProvider } from 'react-hook-form';

import { AddClaimantForm } from 'app/intake/addClaimant/AddClaimantForm';

import { useAddClaimantForm } from 'app/intake/addClaimant/utils';
import { fillForm, relationshipOpts } from './testUtils';

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

  describe('form validation', () => {
    it('disables submit until all fields valid', async () => {
      setup();

      expect(onSubmit).not.toHaveBeenCalled();

      // Select option
      await selectEvent.select(
        screen.getByLabelText('Relationship to the Veteran'),
        [relationshipOpts[3].label]
      );

      // Set organization
      await userEvent.click(
        screen.getByRole('radio', { name: /organization/i })
      );

      await waitFor(() => {
        expect(
          screen.getByRole('textbox', { name: /Organization name/i })
        ).toBeInTheDocument();
      });

      // fill in form
      await fillForm();

      //   Submit the form w/o a submit button
      fireEvent.submit(screen.getAllByRole('textbox')[0]);

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled();
      });
    });
  });
});
