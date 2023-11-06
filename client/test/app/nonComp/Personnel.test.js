import React from 'react';
// import { axe } from 'jest-axe';

import userEvent from '@testing-library/user-event';
import { render, screen } from '@testing-library/react';
import selectEvent from 'react-select-event';

import ReportPage from 'app/nonComp/pages/ReportPage';

describe('Personnel', () => {
  const selectPlaceholder = 'Select...';
  const setup = () => {
    return render(
      <ReportPage />
    );
  };

  const navigateToPersonnel = async () => {
    const addConditionBtn = screen.getByText('Add Condition');

    await userEvent.click(addConditionBtn);

    const selectText = screen.getByText('Select a variable');

    await selectEvent.select(selectText, ['Personnel']);
  };

  it('renders a dropdown with the correct label', async () => {
    setup();
    await navigateToPersonnel();

    expect(screen.getByText('VHA team members')).toBeInTheDocument();
    expect(screen.getAllByText(selectPlaceholder).length).toBe(2);
  });

  it('allows to select multiple options from dropdown', async () => {
    setup();
    await navigateToPersonnel();

    let selectText = screen.getAllByText(selectPlaceholder);
    const teamMember1 = 'Option 1';

    await selectEvent.select(selectText[1], [teamMember1]);

    selectText = screen.getByText(teamMember1);
    const teamMember2 = 'Option 2';

    await selectEvent.select(selectText, [teamMember2]);

    expect(screen.getByText(teamMember1)).toBeInTheDocument();
    expect(screen.getByText(teamMember2)).toBeInTheDocument();
  });
});
