import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import sinon from 'sinon';

import FilterSummary from '../../../app/components/FilterSummary';

describe('FilterSummary', () => {
  let wrapper;
  let props;
  const clearFunction = () => ({});

  beforeEach(() => {
    props = {
      filteredByList: {},
      clearFilteredByList: sinon.spy(clearFunction)
    };
  });

  context('renders', () => {
    it('does not render anything if filteredByList is empty', () => {
      wrapper = mount(
        <FilterSummary {...props} />
      );

      expect(wrapper.find('div')).to.have.length(0);
    });

    it('renders if filteredByList has filters', () => {
      props.filteredByList = Object.assign({ type: ['EstablishClaim'] }, props.filteredByList);
      wrapper = mount(
        <FilterSummary {...props} />
      );

      expect(wrapper.find('div')).to.have.length(1);
    });

    it('calls clearFilteredByList when link is clicked', () => {
      props.filteredByList = Object.assign({ type: ['EstablishClaim'] }, props.filteredByList);
      wrapper = mount(
        <FilterSummary {...props} />
      );

      wrapper.find('a').simulate('click');

      expect(props.clearFilteredByList.calledOnce).to.equal(true);
    });
  });
});
