import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import Logo from '../../../app/components/Logo';

describe('Logo', () => {
  it('renders default logo', () => {
    const wrapper = shallow(<Logo />);

    expect(wrapper.find('.cf-logo-image-default')).to.have.length(1);
  });

  it('renders e-Folder Express logo', () => {
    const wrapper = shallow(<Logo app="efolder"/>);

    expect(wrapper.find('.cf-logo-image-efolder')).to.have.length(1);
  });

  it('renders certification logo', () => {
    const wrapper = shallow(<Logo app="certification"/>);

    expect(wrapper.find('.cf-logo-image-certification')).to.have.length(1);
  });

  it('renders dispatch logo', () => {
    const wrapper = shallow(<Logo app="dispatch"/>);

    expect(wrapper.find('.cf-logo-image-dispatch')).to.have.length(1);
  });

  it('renders reader logo', () => {
    const wrapper = shallow(<Logo app="reader"/>);

    expect(wrapper.find('.cf-logo-image-reader')).to.have.length(1);
  });

  it('renders feedback logo', () => {
    const wrapper = shallow(<Logo app="feedback"/>);

    expect(wrapper.find('.cf-logo-image-feedback')).to.have.length(1);
  });
});
