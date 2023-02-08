import React from 'react';
import { render, screen } from '@testing-library/react';
import { CavcDashboardDetails } from '../../../../app/queue/cavcDashboard/CavcDashboardDetails';
import CAVC_REMAND_SUBTYPES from '../../../../constants/CAVC_REMAND_SUBTYPES';

const createRemandProp = (subtype) => {
  return {
    source_appeal_decision_date: '2022-02-01',
    source_appeal_docket_number: '210501-1',
    decision_date: '2022-04-01',
    cavc_docket_number: '22-0010',
    remand_subtype: subtype
  };
};

const renderCavcDashboardDetails = async (remand, userCanEdit) => {
  const props = { remand, userCanEdit };

  return render(<CavcDashboardDetails {...props} />);
};

describe('CavcDashboardDetails', () => {
  const jmrSubtypes = Object.values(CAVC_REMAND_SUBTYPES).filter((val) => val !== 'mdr');

  it('displays correct values with jmr remand subtypes', async () => {
    jmrSubtypes.forEach((subtype) => async () => {
      const remand = createRemandProp(subtype);

      await renderCavcDashboardDetails(remand, false);
      const jmrSpan = [...document.querySelectorAll('span')].filter((el) => el.textContent.includes('Yes'));

      expect(screen.getByText('02/01/22')).toBeTruthy();
      expect(screen.getByText(remand.source_appeal_docket_number)).toBeTruthy();
      expect(screen.getByText('04/01/22')).toBeTruthy();
      expect(screen.getByText(remand.cavc_docket_number)).toBeTruthy();
      expect(jmrSpan.length).toBe(1);
      expect(jmrSpan[0].textContent).toBe('Yes');
    });
  });

  it('displays correct values with no remand subtype provided', async () => {
    const remand = createRemandProp();

    await renderCavcDashboardDetails(remand, false);
    const jmrSpan = [...document.querySelectorAll('span')].filter((el) => el.textContent.includes('No'));

    expect(screen.getByText('02/01/22')).toBeTruthy();
    expect(screen.getByText(remand.source_appeal_docket_number)).toBeTruthy();
    expect(screen.getByText('04/01/22')).toBeTruthy();
    expect(screen.getByText(remand.cavc_docket_number)).toBeTruthy();
    expect(jmrSpan.length).toBe(1);
    expect(jmrSpan[0].textContent).toBe('No');
  });

  it('edit button is disabled/hidden if not a member of OAI', async () => {
    const remand = createRemandProp();

    await renderCavcDashboardDetails(remand, false);

    const editButton = screen.getByRole('button', { description: 'Edit', hidden: true });

    expect(editButton).toBeDisabled();
    expect(editButton).not.toBeVisible();
  });

  it('edit button is enabled/visible if member of OAI', async () => {
    const remand = createRemandProp();

    await renderCavcDashboardDetails(remand, true);

    const editButton = screen.getByRole('button', { description: 'Edit' });

    expect(editButton).toBeEnabled();
    expect(editButton).toBeVisible();
  });
});
