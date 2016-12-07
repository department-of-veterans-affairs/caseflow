import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
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
});
