import React from 'react';
import { axe } from 'jest-axe';
import selectEvent from 'react-select-event';
import { screen, render, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { AddClaimantPage } from 'app/intake/addClaimant/AddClaimantPage';
import { IntakeProviders } from '../../testUtils';

describe('AddClaimantPage', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = () => {
    return render(<AddClaimantPage />, { wrapper: IntakeProviders });
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

  describe('No Claimant', () => {
    setup();

    it('does not render name fields', () => {
      const nameFields = screen.queryByLabelText('nameFields');

      expect(nameFields).not.toBeInTheDocument();
    });

    it('does not render additional fields', async () => {
      const additionalFields = screen.queryByLabelText('additionalFields');

      expect(additionalFields).not.toBeInTheDocument();
    });

    it('does not render partyType radio fields', () => {
      const partyType = screen.queryByText('Is the claimant an organization or individual?');

      expect(partyType).not.toBeInTheDocument();
    });

  });

  describe('Child Claimant', () => {
    beforeEach(async () => {
      jest.clearAllMocks();
      setup();
      await selectEvent.select(screen.getByRole('textbox'), 'Child');
    });

    it('renders name fields', () => {
      const nameFields = screen.getByLabelText('nameFields');

      expect(nameFields).toBeInTheDocument();
    });

    it('renders additional fields', () => {
      const additionalFields = screen.getByLabelText('additionalFields');

      expect(additionalFields).toBeInTheDocument();
    });

    it('does not render partyType radio fields', () => {
      const partyType = screen.queryByText('Is the claimant an organization or individual?');

      expect(partyType).not.toBeInTheDocument();
    });
  });

  describe('Spouse Claimant', () => {
    beforeEach(async () => {
      jest.clearAllMocks();
      setup();
      await selectEvent.select(screen.getByRole('textbox'), 'Spouse');
    });

    it('renders name fields', () => {
      const nameFields = screen.getByLabelText('nameFields');

      expect(nameFields).toBeInTheDocument();
    });

    it('renders additional fields', () => {
      const additionalFields = screen.getByLabelText('additionalFields');

      expect(additionalFields).toBeInTheDocument();
    });

    it('does not render partyType radio fields', () => {
      const partyType = screen.queryByText('Is the claimant an organization or individual?');

      expect(partyType).not.toBeInTheDocument();
    });
  });

  describe('Attorney', () => {
    beforeEach(async () => {
      jest.clearAllMocks();
      setup();
      await selectEvent.select(screen.getByRole('textbox'), 'Attorney (previously or currently)');
    });

    it('does not render name fields', () => {
      const nameFields = screen.queryByLabelText('nameFields');

      expect(nameFields).not.toBeInTheDocument();
    });

    it('does not render additional fields', () => {
      const additionalFields = screen.queryByLabelText('additionalFields');

      expect(additionalFields).not.toBeInTheDocument();
    });

    it('does not render partyType radio fields', () => {
      const partyType = screen.queryByText('Is the claimant an organization or individual?');

      expect(partyType).not.toBeInTheDocument();
    });

    it('does render claimant name input', () => {
      const claimantName = screen.queryByText("Claimant's name");

      expect(claimantName).toBeInTheDocument();
    });
  });

  describe('Other Claimant', () => {
    beforeEach(async () => {
      jest.clearAllMocks();
      setup();
      await selectEvent.select(screen.getByRole('textbox'), 'Other');
    });

    it('does not render name fields', () => {
      const nameFields = screen.queryByLabelText('nameFields');

      expect(nameFields).not.toBeInTheDocument();
    });

    it('does not render additional fields', () => {
      const additionalFields = screen.queryByLabelText('additionalFields');

      expect(additionalFields).not.toBeInTheDocument();
    });

    it('does render partyType radio fields', () => {
      const partyType = screen.getByText('Is the claimant an organization or individual?');

      expect(partyType).toBeInTheDocument();
    });

    describe('Individual', () => {
      beforeEach(async () => {
        const individualRadio = screen.getByLabelText('Individual');

        await act(async () => {
          userEvent.click(individualRadio);
        });
      });

      it('successfully selects Individual', () => {
        const individualRadio = screen.getByLabelText('Individual');

        expect(individualRadio.checked).toBe(true);
      });

      it('renders name fields', async () => {
        const nameFields = screen.getByLabelText('nameFields');

        expect(nameFields).toBeInTheDocument();
      });

      it('renders additional fields', () => {
        const additionalFields = screen.getByLabelText('additionalFields');

        expect(additionalFields).toBeInTheDocument();
      });

      it('does not render organization field', () => {
        const organizationField = screen.queryByLabelText('organization');

        expect(organizationField).not.toBeInTheDocument();
      });
    });

    describe('Organization', () => {
      beforeEach(async () => {
        const organizationRadio = screen.getByLabelText('Organization');

        await act(async () => {
          userEvent.click(organizationRadio);
        });
      });

      it('successfully selects Organization', () => {
        const organizationRadio = screen.getByLabelText('Organization');

        expect(organizationRadio.checked).toBe(true);
      });

      it('does not render name fields', async () => {
        const nameFields = screen.queryByLabelText('nameFields');

        expect(nameFields).not.toBeInTheDocument();
      });

      it('renders additional fields', () => {
        const additionalFields = screen.getByLabelText('additionalFields');

        expect(additionalFields).toBeInTheDocument();
      });

      it('does render organization field', () => {
        const organizationField = screen.getByText('Organization name');

        expect(organizationField).toBeInTheDocument();
      });
    });

  });
});
