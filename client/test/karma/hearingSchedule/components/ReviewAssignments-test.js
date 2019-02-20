import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { MemoryRouter } from 'react-router-dom';
import ReviewAssignments from '../../../../app/hearingSchedule/components/ReviewAssignments';

describe('ReviewAssignments', () => {
  it('renders the RO/CO alert', () => {
    const wrapper = mount(<MemoryRouter><ReviewAssignments
      schedulePeriod={{ type: 'RoSchedulePeriod' }}
    /></MemoryRouter>);

    expect(wrapper.text()).to.include('We have assigned your video hearings');
  });

  it('renders the judge alert', () => {
    const wrapper = mount(<MemoryRouter><ReviewAssignments
      schedulePeriod={{ type: 'JudgeSchedulePeriod' }}
    /></MemoryRouter>);

    expect(wrapper.text()).to.include('We have assigned your judges');
  });

  it('renders the modal if displayConfirmationModal is true', () => {
    const wrapper = mount(<MemoryRouter><ReviewAssignments
      displayConfirmationModal
      schedulePeriod={{ type: 'JudgeSchedulePeriod' }}
    /></MemoryRouter>);

    expect(wrapper.text()).to.include('Please confirm Caseflow upload');
  });

  it('redirects if the schedule period is finalized', () => {
    const wrapper = mount(<MemoryRouter><ReviewAssignments
      displayConfirmationModal
      schedulePeriod={{
        type: 'JudgeSchedulePeriod',
        finalized: true
      }}
    /></MemoryRouter>);

    expect(wrapper).to.deep.equal({ length: 1 });
  });
});
