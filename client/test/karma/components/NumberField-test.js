import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import NumberField from '../../../app/components/NumberField';

describe('NumberField', () => {
  let wrapper;
  let input;
  let state = { value: 3 };

  beforeEach(() => {
    wrapper = mount(
      <NumberField
        name="foo"
        isInteger={true}
        value={state.value}
        onChange={(val) => {
          state.value = val;
        }}
      />
    );

    input = wrapper.find('input');
  });

  it('renders', () => {
    expect(wrapper.find('input')).to.have.length(1);
  });

  it('allows integer input when isInteger is true', () => {
    input.simulate('change', { target: { value: '2' } });
    expect(state.value).to.be.eq(2);
  });

  it('disallows "+" as input when isInteger is true', () => {
    input.simulate('change', { target: { value: '+' } });
    expect(state.value).to.be.eq('');
  });

  it('disallows "." as input when isInteger is true', () => {
    input.simulate('change', { target: { value: '.' } });
    expect(state.value).to.be.eq('');
  });

  it('disallows "e" as input when isInteger is true', () => {
    input.simulate('change', { target: { value: 'e' } });
    expect(state.value).to.be.eq('');
  });

  it('allows non-integer input when isInteger is false', () => {
    wrapper = mount(
      <NumberField
        name="foo"
        value={state.value}
        onChange={(val) => {
          state.value = val;
        }}
      />
    );
    input = wrapper.find('input');
    input.simulate('change', { target: { value: '2.1' } });
    expect(state.value).to.be.eq(2.1);
  });
});
