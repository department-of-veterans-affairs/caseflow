import React from 'react';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { ReviewAssignments } from '../../../../../../client/app/hearings/components/ReviewAssignments';

describe('ReviewAssignments', () => {
  it('renders the RO/CO alert', () => {
    render(
      <MemoryRouter>
        <ReviewAssignments schedulePeriod={{ type: 'RoSchedulePeriod', hearingDays: [] }} />
      </MemoryRouter>
    );

    expect(screen.getByText('We have assigned your hearings days')).toBeInTheDocument();
  });

  it('renders the modal if displayConfirmationModal is true', () => {
    render(
      <MemoryRouter>
        <ReviewAssignments displayConfirmationModal schedulePeriod={{ type: 'RoSchedulePeriod', hearingDays: [] }} />
      </MemoryRouter>
    );

    expect(screen.getByText('Please confirm Caseflow upload')).toBeInTheDocument();
  });

  // This test appears to no longer be applicable (and is failing after test suite updates)
  // It appears to have been written when the component included a <Redirect> component, but that's no longer there
  // it('redirects if the schedule period is finalized', () => {
  //   const wrapper = mount(<MemoryRouter><ReviewAssignments
  //     displayConfirmationModal
  //     schedulePeriod={{
  //       type: 'JudgeSchedulePeriod',
  //       finalized: true
  //     }}
  //   /></MemoryRouter>);

  //   expect(wrapper).to.deep.equal({ length: 1 });
  // });
});
