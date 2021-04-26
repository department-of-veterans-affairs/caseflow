import React from 'react';
import { screen, render, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import { axe } from 'jest-axe';
import { FormProvider } from 'react-hook-form';

import { AddClaimantForm } from 'app/intake/addClaimant/AddClaimantForm';

import { useAddClaimantForm } from 'app/intake/addClaimant/utils';
import { fillForm, relationshipOpts } from './testUtils';

const FormWrapper = ({ children, defaultValues }) => {
  const methods = useAddClaimantForm({ defaultValues });

  return <FormProvider {...methods}>{children}</FormProvider>;
};

describe('AddClaimantForm', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const onSubmit = jest.fn();

  const setup = (props = { onSubmit }, wrapperProps = {}) => {
    return render(<AddClaimantForm {...props} />, {
      wrapper: ({ children }) => (
        <FormWrapper {...wrapperProps}>{children}</FormWrapper>
      ),
    });
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
    }, 15000);
  });

  describe('default values', () => {
    const defaultValues = {
      relationship: 'other',
      partyType: 'individual',
      firstName: 'Jane',
      lastName: 'Doe',
      addressLine1: '123 Main St',
      city: 'San Francisco',
      state: 'CA',
      zip: '94123',
      vaForm: 'false',
    };

    it('prepopulates with default values', async () => {
      const { container } = setup({}, { defaultValues });

      await waitFor(() => {
        expect(screen.getByDisplayValue(defaultValues.firstName)).toBeInTheDocument();
        expect(screen.getByDisplayValue(defaultValues.city)).toBeInTheDocument();
      });

      expect(container).toMatchSnapshot();
    });
  });
});
