import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { MemoryRouter } from 'react-router-dom';
import BuildSchedule from '../../../../app/hearingSchedule/components/BuildSchedule';

describe('BuildSchedule', () => {
  it('renders table with upload history', () => {
    const wrapper = mount(<MemoryRouter><BuildSchedule
      pastUploads={[
        {
          startDate: '10/01/2018',
          endDate: '03/31/2019',
          type: 'JudgeSchedulePeriod',
          createdAt: '07/03/2018',
          userFullName: 'Justin Madigan',
          fileName: 'fake file name'
        }
      ]}
    /></MemoryRouter>);

    expect(wrapper.text()).to.include('10/01/2018 - 03/31/2019');
    expect(wrapper.text()).to.include('Judge');
    expect(wrapper.text()).to.include('07/03/2018');
    expect(wrapper.text()).to.include('Justin Madigan');
    expect(wrapper.text()).to.include('Download');
  });
});
