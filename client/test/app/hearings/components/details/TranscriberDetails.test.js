import React from 'react';
import { mount } from 'enzyme';
import TranscriberDetails from 'app/hearings/components/details/TranscriberDetails';

describe('TranscriberDetails', () => {
  const defaultHearing = {
    determineServiceName: 'Service Name',
    scheduledTime: '2024-09-18T12:00:00Z',
    dateReceiptRecording: '2024-09-19T12:00:00Z',
  };

  it('renders correctly with provided hearing details', () => {
    const wrapper = mount(<TranscriberDetails hearing={defaultHearing} />);
    
    expect(wrapper.find('p').at(0).text()).toBe('Service Name');
    expect(wrapper.find('p').at(1).text()).toBe('2024-09-18T12:00:00Z');
    expect(wrapper.find('p').at(2).text()).toBe('2024-09-19T12:00:00Z');
  });

  it('displays N/A for missing hearing details', () => {
    const wrapper = mount(<TranscriberDetails hearing={{}} />);
    
    expect(wrapper.find('p').at(0).text()).toBe('N/A');
    expect(wrapper.find('p').at(1).text()).toBe('N/A');
    expect(wrapper.find('p').at(2).text()).toBe('N/A');
  });

  it('displays N/A for specific missing properties', () => {
    const hearing = {
      determineServiceName: 'Service Name',
      scheduledTime: null,
      dateReceiptRecording: '2024-09-19T12:00:00Z',
    };
    
    const wrapper = mount(<TranscriberDetails hearing={hearing} />);
    
    expect(wrapper.find('p').at(0).text()).toBe('Service Name');
    expect(wrapper.find('p').at(1).text()).toBe('N/A');
    expect(wrapper.find('p').at(2).text()).toBe('2024-09-19T12:00:00Z');
  });
});
