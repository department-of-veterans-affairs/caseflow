import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import sinon from 'sinon';

import PaginationButton from '../../../app/components/PaginationButton';

describe('PaginationButton', () => {
  let wrapper;
  let props;
  const clickFunction = () => ({});

  beforeEach(() => {
    props = {
      currentPage: 0,
      index: 0,
      handleChange: sinon.spy(clickFunction)
    };
  });

  context('renders', () => {
    it('works', () => {
      wrapper = mount(
        <PaginationButton {...props} />
      );

      expect(wrapper.find('button')).to.have.length(1);
      expect(wrapper.text()).to.equal('1');
    });

    it('handleClick is called on click', () => {
      wrapper = mount(
        <PaginationButton {...props} />
      );

      wrapper.find('button').simulate('click');

      expect(props.handleChange.calledOnce).to.equal(true);
    });

    it('button has className if currentPage', () => {
      wrapper = mount(
        <PaginationButton {...props} />
      );

      expect(wrapper.find('button').hasClass('cf-current-page')).to.equal(true);
    });
  });
});
