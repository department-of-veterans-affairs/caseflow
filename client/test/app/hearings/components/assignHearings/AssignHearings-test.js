import React from 'react';
import { mount } from 'enzyme';
import { MemoryRouter } from 'react-router-dom';
import { AssignHearings } from '../../../../app/hearings/components/assignHearings/AssignHearings';

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

    expect(wrapper.text()).toEqual(expect.arrayContaining(['Regional Office']));
    expect(wrapper.text()).toEqual(expect.arrayContaining(['Togus, ME']));
  });
});
