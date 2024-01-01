import React from 'react';
import { shallow } from 'enzyme';
import StaticLever from 'app/caseflowDistribution/components/StaticLever';

jest.mock('app/styles/caseDistribution/StaticLevers.module.scss', () => '');
describe('StaticLever', () => {
  const lever = {
    title: 'Test Title',
    description: 'Test Description',
    data_type: 'number',
    value: 10,
    unit: 'Days',
    is_active: true,
    options: [],
  };

  it('renders the title', () => {
    const wrapper = shallow(<StaticLever lever={lever} />);

    expect(wrapper.find('td').at(0).
      text()).toEqual('Test Title');
  });

  it('renders the description', () => {
    const wrapper = shallow(<StaticLever lever={lever} />);

    expect(wrapper.find('td').at(1).
      text()).toEqual('Test Description');
  });

  it('renders the value and unit', () => {
    const wrapper = shallow(<StaticLever lever={lever} />);

    expect(wrapper.find('td').at(2).
      text()).toEqual('10 Days');
  });
});
