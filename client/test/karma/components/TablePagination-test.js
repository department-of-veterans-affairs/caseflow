import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import sinon from 'sinon';

import TablePagination from '../../../app/components/TablePagination';
import { createTask } from '../../factory';

describe('TablePagination', () => {
  let wrapper;
  let props;
  const updateFunction = () => ({});

  beforeEach(() => {
    props = {
      currentPage: 0,
      paginatedData: [
        createTask(3),
        createTask(3),
        createTask(3)
      ],
      totalCasesCount: 9,
      updatePage: sinon.spy(updateFunction)
    };
  });

  context('renders', () => {
    it('works', () => {
      wrapper = mount(
        <TablePagination {...props} />
      );

      expect(wrapper.find('button')).to.have.length(5);
    });

    it('handleChange calls updatePage', () => {
      wrapper = mount(
        <TablePagination {...props} />
      );

      wrapper.instance().handleChange(1);

      expect(props.updatePage.calledOnce).to.equal(true);
    });

    it('handleNext calls updatePage', () => {
      wrapper = mount(
        <TablePagination {...props} />
      );

      wrapper.instance().handleNext(1);

      expect(props.updatePage.calledOnce).to.equal(true);
    });

    it('handlePrevious calls updatePage', () => {
      wrapper = mount(
        <TablePagination {...props} />
      );

      wrapper.instance().handlePrevious(1);

      expect(props.updatePage.calledOnce).to.equal(true);
    });

    it('pagination summary displays the correct text', () => {
      wrapper = mount(
        <TablePagination {...props} />
      );

      expect(wrapper.text()).to.include('Viewing 1-3 of 9 total cases');
    });

    it('Previous button should be disabled on page 1', () => {
      wrapper = mount(
        <TablePagination {...props} />
      );

      expect(wrapper.find('button').first().
        getDOMNode().disabled).to.equal(true);
    });

    it('Next button should be disabled on last page', () => {
      const newProps = Object.assign({}, props);

      newProps.currentPage = 2;
      wrapper = mount(
        <TablePagination {...newProps} />
      );

      expect(wrapper.find('button').last().
        getDOMNode().disabled).to.equal(true);
    });
  });
});
