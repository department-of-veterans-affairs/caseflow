import React from 'react';
import { expect } from 'chai';
import { shallow, mount } from 'enzyme';
import LoadingSymbol from '../../../app/components/LoadingSymbol';

describe('LoadingSymbol', () => {
  it('renders with default colors', () => {
    const wrapper = shallow(<LoadingSymbol />);

    expect(wrapper.find('.cf-loading-symbol')).to.have.length(1);
    expect(wrapper.find('[data-front-color="#323a45"]')).to.have.length(1);
    expect(wrapper.find('[data-back-color="#323a45"]')).to.have.length(1);
  });

  it('renders with custom front color', () => {
    const wrapper = shallow(<LoadingSymbol frontColor="red"/>);

    expect(wrapper.find('[data-front-color="red"]')).to.have.length(1);
  });

  it('renders with custom back color', () => {
    const wrapper = shallow(<LoadingSymbol backColor="red"/>);

    expect(wrapper.find('[data-back-color="red"]')).to.have.length(1);
  });

  it('renders on a pill', () => {
    const wrapper = shallow(<LoadingSymbol onPill={true}/>);

    expect(wrapper.find('.cf-loading-symbol.on-pill')).to.have.length(1);
  });

  it('renders with a caption', () => {
    const wrapper = shallow(<LoadingSymbol caption="Loading, please wait..."/>);

    expect(wrapper.find('.cf-loading-symbol .caption')).to.have.length(1);
  });

/*
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
*/
});
