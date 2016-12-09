import React from 'react';
import { expect } from 'chai';
import { shallow, mount } from 'enzyme';
import Button from '../../app/components/Button';

describe('Button', () => {
  it('does not render while loading', () => {
    let onChange = () => true;
    const wrapper = shallow(<Button name="foo" onChange={onChange} loading={true} />);

    expect(wrapper.find('button')).to.have.length(0);
  });
  it('renders while not loading', () => {
    let onChange = () => true;
    const wrapper = shallow(<Button name="foo" onChange={onChange} loading={false} />);

    expect(wrapper.find('button')).to.have.length(1);
  });
  it('calls the on change function', () => {
    let isCalled = false;
    let onClick = () => {
      isCalled = true;
    };
    let wrapper;

    wrapper = mount(<Button name="foo" onClick={onClick} loading={false} />);
    wrapper.find('button').simulate('click');
    expect(isCalled).to.be.eq(true);
  });
});
