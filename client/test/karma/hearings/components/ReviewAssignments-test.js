import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { MemoryRouter } from 'react-router-dom';
import { ReviewAssignments } from '../../../../app/hearings/components/ReviewAssignments';

describe('ReviewAssignments', () => {
  it('renders the RO/CO alert', () => {
    const wrapper = mount(
      <MemoryRouter>
        <ReviewAssignments schedulePeriod={{ type: 'RoSchedulePeriod' }} />
      </MemoryRouter>
    );

    expect(wrapper.text()).to.include('We have assigned your hearings days');
  });

  it('renders the modal if displayConfirmationModal is true', () => {
    const wrapper = mount(
      <MemoryRouter>
        <ReviewAssignments displayConfirmationModal schedulePeriod={{ type: 'RoSchedulePeriod' }} />
      </MemoryRouter>
    );

    expect(wrapper.text()).to.include('Please confirm Caseflow upload');
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
