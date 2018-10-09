import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { MemoryRouter } from 'react-router-dom';
import AssignHearings from '../../../../app/hearingSchedule/components/AssignHearings';

describe.skip('AssignHearings', () => {
  it('renders table with upload history', () => {
    const wrapper = mount(<MemoryRouter><AssignHearings
      regionalOffices={{
        RO01: {
          city: 'Boston',
          state: 'MA'
        },
        RO02: {
          city: 'Togus',
          state: 'ME'
        }
      }}
      selectedRegionalOffice={{
        label: 'Togus, ME',
        value: 'RO02'
      }}
    /></MemoryRouter>);

    expect(wrapper.text()).to.include('Regional Office');
    expect(wrapper.text()).to.include('Togus, ME');
  });
});
