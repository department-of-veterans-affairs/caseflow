import React from 'react';
import { mount } from 'enzyme';
import { MemoryRouter } from 'react-router-dom';
import BuildSchedule from '../../../../../../client/app/hearings/components/BuildSchedule';

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
          fileName: 'fake file name',
          finalized: true
        }
      ]}
    /></MemoryRouter>);

    expect(wrapper.text().includes('Judge')).toBe(true);
    expect(wrapper.text().includes('07/03/2018')).toBe(true);
    expect(wrapper.text().includes('Justin Madigan')).toBe(true);
    expect(wrapper.text().includes('Download')).toBe(true);
  });

  it('renders a success alert when a schedule period has been created', () => {
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
      displaySuccessMessage
      schedulePeriod={{
        type: 'JudgeSchedulePeriod',
        startDate: '2018-07-04',
        endDate: '2018-07-26'
      }}
    /></MemoryRouter>);

    expect(wrapper.text().includes('You have successfully assigned judges to hearings')).toBe(true);
  });
});
