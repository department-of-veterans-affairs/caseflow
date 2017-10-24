import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import { DocketsContainer } from '../../../app/hearings/DocketsContainer';
import Dockets from '../../../app/hearings/Dockets';

/* eslint-disable camelcase */
describe('DocketsContainer', () => {
  it('notifies user when no dockets are returned', () => {
    const wrapper = shallow(<DocketsContainer veteran_law_judge={{ name: 'me' }} dockets={{}} />);

    expect(wrapper.text()).to.include('You have no upcoming hearings.');
  });

  it('renders loaded dockets', () => {
    const dockets = {
      '2017-06-17': {
        date: '2017-06-17T17:52:09.742-04:00',
        hearings_array: [{
          id: 1,
          appeal_id: 68468,
          appellant_last_first_mi: 'VanBuren, James A.',
          date: '2017-06-30T14:03:42.714Z',
          representative_name: 'Military Order of the Purple Heart',
          request_type: 'CO',
          user_id: 9,
          vacols_id: 'f10b9ed6a',
          vbms_id: '3bf55b922',
          venue: {
            city: 'Baltimore',
            state: 'MD',
            timezone: 'America/New_York'
          },
          worksheet_comments_for_attorney: 'Look for knee-related medical records',
          worksheet_contentions: 'The veteran believes their knee is hurt',
          worksheet_evidence: 'Medical exam occurred on 10/10/2008',
          worksheet_military_service: null,
          worksheet_witness: 'Jane Doe attended'
        }],
        type: 'central_office',
        venue: {
          city: 'Baltimore',
          state: 'MD',
          timezone: 'America/New_York'
        }
      }
    };
    const wrapper = shallow(<DocketsContainer veteran_law_judge={{ name: 'me' }} dockets={dockets} />);

    expect(wrapper.find(Dockets)).to.have.length(1);
  });
});
