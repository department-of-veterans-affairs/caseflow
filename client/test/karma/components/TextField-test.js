import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import TextField from '../../../app/components/TextField';

describe('TextField', () => {
  it('renders', () => {
    let onChange = () => true;
    const wrapper = mount(<TextField name="foo" onChange={onChange} />);

    expect(wrapper.find('input')).to.have.length(1);
  });
});
