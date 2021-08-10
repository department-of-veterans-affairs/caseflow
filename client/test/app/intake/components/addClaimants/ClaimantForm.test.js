import React from 'react';
import { screen, render, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import { axe } from 'jest-axe';
import { FormProvider } from 'react-hook-form';

import { ClaimantForm } from 'app/intake/addClaimant/ClaimantForm';

import { useClaimantForm } from 'app/intake/addClaimant/utils';
import { fillForm, relationshipOpts } from './testUtils';
import { ERROR_EMAIL_INVALID_FORMAT } from 'app/../COPY';

const FormWrapper = ({ children, defaultValues }) => {
  const methods = useClaimantForm({ defaultValues });

  return <FormProvider {...methods}>{children}</FormProvider>;
};

describe('ClaimantForm', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const onSubmit = jest.fn();

  const setup = (props = { onSubmit }, wrapperProps = {}) => {
    return render(<ClaimantForm {...props} />, {
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
    const selectRelationship = async (number) => {
      await selectEvent.select(
        screen.getByLabelText('Relationship to the Veteran'),
        [relationshipOpts[number].label]
      );
    };

    it('disables submit until all  fields valid', async () => {
      setup();

      expect(onSubmit).not.toHaveBeenCalled();

      // Select option
      await selectRelationship(3);

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

      // Submit the form w/o a submit button
      fireEvent.submit(screen.getAllByRole('textbox')[0]);

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled();
      });
    }, 15000);

    it('renders inline email validation error', async () => {
      setup();
      await selectRelationship(2);

      const invalidEmail = 'mail@address';
      const validEmail = 'mail@address.com';
      const emailTextbox = screen.getByRole('textbox', { name: /Claimant email Optional/i });

      const inputEmail = async (email) => {
        // input email addresss
        await userEvent.type(emailTextbox, email);

        // trigger onBlur
        expect(emailTextbox).toBe(document.activeElement);
        userEvent.tab(); /* press tab key */
      };

      await inputEmail(invalidEmail);

      await waitFor(() => {
        expect(emailTextbox.value).toBe(invalidEmail);
        expect(screen.getByText(ERROR_EMAIL_INVALID_FORMAT)).toBeDefined();
      });

      // CLEAR INPUT
      fireEvent.change(emailTextbox, { target: { value: '' } });
      expect(emailTextbox.value).toBe('');

      await inputEmail(validEmail);

      await waitFor(() => {
        expect(emailTextbox.value).toBe(validEmail);
        expect(screen.queryByText(ERROR_EMAIL_INVALID_FORMAT)).toBeNull();
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
