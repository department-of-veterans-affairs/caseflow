import React from 'react';
import { mount } from 'enzyme';
import { MemoryRouter } from 'react-router-dom';
import { ReviewAssignments } from '../../../../../../client/app/hearings/components/ReviewAssignments';

describe('ReviewAssignments', () => {
  it('renders the RO/CO alert', () => {
    const wrapper = mount(
      <MemoryRouter>
        <ReviewAssignments schedulePeriod={{ type: 'RoSchedulePeriod', hearingDays: [] }} />
      </MemoryRouter>
    );

    expect(wrapper.text().includes(['We have assigned your hearings days'])).toBe(true);
  });

  it('renders the modal if displayConfirmationModal is true', () => {
    const wrapper = mount(
      <MemoryRouter>
        <ReviewAssignments displayConfirmationModal schedulePeriod={{ type: 'RoSchedulePeriod', hearingDays: [] }} />
      </MemoryRouter>
    );

    expect(wrapper.text().includes('Please confirm Caseflow upload')).toBe(true);
    // expect(2).equals(2);
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
