import React from 'react';
import { screen, render, fireEvent, within, act, waitFor} from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import { STATES } from 'app/constants/AppConstants';

import COPY from 'app/../COPY';

import { AddClaimantPage } from 'app/intake/addClaimant/AddClaimantPage';
import { IntakeProviders } from '../../testUtils';

const relationshipOpts = [
  { value: 'attorney', label: 'Attorney (previously or currently)' },
  { value: 'child', label: 'Child' },
  { value: 'spouse', label: 'Spouse' },
  { value: 'other', label: 'Other' },
];

describe('AddClaimantPage', () => {
  const onSubmit = jest.fn();
  const onBack = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });
  const defaults = { onSubmit, onBack};
  const setup = () => {
    return render(<AddClaimantPage  {...defaults}/>, { wrapper: IntakeProviders });
  };

  it('renders default state correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
    expect(
      screen.getByText('Add Claimant')
    ).toBeInTheDocument();
  });

  it('fires onBack', async () => {
    const { container } = setup();

    const backButton = screen.getByRole('button', { name: /back/i });
    expect(onBack).not.toHaveBeenCalled();
     
    await userEvent.click(backButton);
    expect(onBack).not.toHaveBeenCalled();
  });
 
 describe('form validation', () => {
  const organization = 'Tista';
    const street1= '1000 Monticello'
    const city = 'Washington'
    const zip = '2000'
    const country = 'USA'

    const fillForm = async () => {
      //   Enter organization
      await userEvent.type(screen.getByRole('textbox', { name: /Organization name/i }), organization);

      //   Enter  Street1 
      await userEvent.type(screen.getByRole('textbox', { name: /Street address 1/i }), street1);

      //   Enter city
      await userEvent.type(screen.getByRole('textbox', { name: /City/i }), city);
      // select state
      await selectEvent.select(screen.getByLabelText('State'), [
      STATES[7].label,
      ]);
      
      // Enter zip
      await userEvent.type(screen.getByRole('textbox', { name: /Zip/i }), zip);
      // Enter country
      await userEvent.type(screen.getByRole('textbox', { name: /Country/i }), country);

      await userEvent.click(
      screen.getByRole('radio', { name: /no/i })
    );
    };

    it('disables submit until all fields valid', async () => {
      const { container } = setup();
      const submit = screen.getByRole('button', { name: /Continue to next step/i });

      expect(onSubmit).not.toHaveBeenCalled();

      // submit button disabled
      await waitFor(() => {
        expect(submit).toBeDisabled();
      });

      // Select option
      await selectEvent.select(screen.getByLabelText('Relationship to the Veteran'), [
      relationshipOpts[3].label,
      ]);

      // Set organization
      await fireEvent.click(
        screen.getByRole('radio', { name: /organization/i })
      );
      
      await waitFor(() => {
        expect(screen.getByRole('textbox', { name: /Organization name/i })).toBeInTheDocument();
      });
      
      // fill in form
      await fillForm()

      // submit enabled
      await waitFor(() => {
        expect(submit).toBeEnabled();
      });

      await userEvent.click(submit);
    });
 });
});
