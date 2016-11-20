import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import TextField from '../app/components/TextField';

describe('test', () => {
  it('renders', () => {
    let onChange = () => {};
    const wrapper = shallow(<TextField name="foo" onChange={onChange} />);
    expect(wrapper.find('input')).to.have.length(1);
  });
});
