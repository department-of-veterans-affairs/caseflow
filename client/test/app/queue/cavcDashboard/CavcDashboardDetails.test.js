import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import { CavcDashboardDetails } from '../../../../app/queue/cavcDashboard/CavcDashboardDetails';

const createDashboardProp = (jmr) => {
  return {
    board_decision_date: '2022-02-01',
    board_docket_number: '210501-1',
    cavc_decision_date: '2022-04-01',
    cavc_docket_number: '22-0010',
    joint_motion_for_remand: jmr || false
  };
};

const renderCavcDashboardDetails = async (dashboard, userCanEdit) => {
  const props = { dashboard, userCanEdit };

  return render(<CavcDashboardDetails {...props} />);
};

describe('CavcDashboardDetails', () => {
  it('displays Joint Motion For Remand correctly when true', async () => {
    const dashboard = createDashboardProp(true);

    await renderCavcDashboardDetails(dashboard, false);
    const jmrSpan = [...document.querySelectorAll('span')].filter((el) => el.textContent.includes('Yes'));

    expect(screen.getByText('02/01/22')).toBeTruthy();
    expect(screen.getByText(dashboard.board_docket_number)).toBeTruthy();
    expect(screen.getByText('04/01/22')).toBeTruthy();
    expect(screen.getByText(dashboard.cavc_docket_number)).toBeTruthy();
    expect(jmrSpan.length).toBe(1);
    expect(jmrSpan[0].textContent).toBe('Yes');
  });

  it('displays Joint Motion For Remand correctly when false', async () => {
    const dashboard = createDashboardProp(false);

    await renderCavcDashboardDetails(dashboard, false);
    const jmrSpan = [...document.querySelectorAll('span')].filter((el) => el.textContent.includes('No'));

    expect(screen.getByText('02/01/22')).toBeTruthy();
    expect(screen.getByText(dashboard.board_docket_number)).toBeTruthy();
    expect(screen.getByText('04/01/22')).toBeTruthy();
    expect(screen.getByText(dashboard.cavc_docket_number)).toBeTruthy();
    expect(jmrSpan.length).toBe(1);
    expect(jmrSpan[0].textContent).toBe('No');
  });

  it('edit button is disabled/hidden if not a member of OAI', async () => {
    const remand = createDashboardProp();

    await renderCavcDashboardDetails(remand, false);

    const editButton = screen.getByRole('button', { description: 'Edit', hidden: true });

    expect(editButton).toBeDisabled();
    expect(editButton).not.toBeVisible();
  });

  it('edit button is enabled/visible if member of OAI', async () => {
    const remand = createDashboardProp();

    await renderCavcDashboardDetails(remand, true);

    const editButton = screen.getByRole('button', { description: 'Edit' });

    expect(editButton).toBeEnabled();
    expect(editButton).toBeVisible();
  });

  it('edit CAVC Details Modal is visible when edit button is clicked', async () => {
    const dashboard = createDashboardProp(true);

    await renderCavcDashboardDetails(dashboard, true);

    const edit = screen.getByRole('button', { description: 'Edit' });

    fireEvent.click(edit);

    const modal = document.getElementById('modal_id');
    const modalSave = document.getElementById('Edit-CAVC-Details-button-id-1');

    expect(screen.getByText('Edit CAVC Details')).toBeTruthy();
    expect(screen.getByLabelText('Board Decision Date')).toBeTruthy();
    expect(screen.getByText('02/01/22')).toBeTruthy();
    expect(screen.getByLabelText('Board Docket Number')).toBeTruthy();
    expect(screen.getByText(dashboard.board_docket_number)).toBeTruthy();
    expect(screen.getByLabelText('CAVC Decision Date')).toBeTruthy();
    expect(screen.getByText('04/01/22')).toBeTruthy();
    expect(screen.getByLabelText('CAVC Docket Number')).toBeTruthy();
    expect(screen.getByText(dashboard.cavc_docket_number)).toBeTruthy();
    expect(modal).toBeVisible();
    expect(modalSave).toBeEnabled();
  });

  it('edit CAVC Details Modal is closed when cancel/close button is clicked', async () => {
    const dashboard = createDashboardProp(true);

    await renderCavcDashboardDetails(dashboard, true);

    const edit = screen.getByRole('button', { description: 'Edit' });

    fireEvent.click(edit);
    const cancelModal = document.getElementById('Edit-CAVC-Details-button-id-0');

    fireEvent.click(cancelModal);
    const modal = document.getElementById('modal_id');

    expect(modal).toBeNull();
  });

  it('save button is disabled when not validated', async () => {
    const dashboard = { board_decision_date: '2022-02-01',
      board_docket_number: '210501',
      cavc_decision_date: '2022-04-01',
      cavc_docket_number: '22',
      joint_motion_for_remand: true };

    await renderCavcDashboardDetails(dashboard, true);

    const edit = screen.getByRole('button', { description: 'Edit' });

    fireEvent.click(edit);

    const modalSave = document.getElementById('Edit-CAVC-Details-button-id-1');

    expect(screen.getByText('Please enter a valid docket number provided by the Board (123456-7).')).toBeTruthy();
    expect(screen.getByText('Please enter a valid docket number provided by CAVC (12-3456).')).toBeTruthy();
    expect(modalSave).toBeDisabled();
  });

});
