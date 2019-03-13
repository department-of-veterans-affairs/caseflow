import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import QueueTable from '../../../app/queue/QueueTable';
import { createTask } from '../../factory';

describe('QueueTable', () => {
  let columns;
  let rowObjects;
  let wrapper;

  beforeEach(() => {
    columns = [
      { header: 'First',
        valueFunction: () => 'fizz' },
      { header: 'Second',
        valueFunction: () => 'buzz' },
      { header: 'Second',
        valueName: 'type' }
    ];

    rowObjects = createTask(3);
  });

  context('renders', () => {
    it('works', () => {
      wrapper = mount(
        <QueueTable columns={columns} rowObjects={rowObjects} summary="test table" slowReRendersAreOk />
      );

      let headerCount = 3;
      let rowCount = 4;
      let cellCount = 9;

      expect(wrapper.find('table')).to.have.length(1);
      expect(wrapper.find('tr')).to.have.length(rowCount);
      expect(wrapper.find('td')).to.have.length(cellCount);
      expect(wrapper.find('th')).to.have.length(headerCount);

      expect(
        wrapper.
          find('td').
          last().
          text()
      ).to.eq('EstablishClaim');
    });

    it('updates filteredByList', () => {
      const additionalRows = createTask(2, { type: 'AttorneyLegacyTask' });

      rowObjects = rowObjects.concat(additionalRows);
      wrapper = mount(
        <QueueTable columns={columns} rowObjects={rowObjects} summary="test table" slowReRendersAreOk />
      );

      wrapper.instance().updateFilteredByList({ type: ['AttorneyLegacyTask'] });
      wrapper.update();

      expect(wrapper.instance().state.filteredByList.type).to.include('AttorneyLegacyTask');
    });

    it('displays the correctly filtered data', () => {
      const additionalRows = createTask(2, { type: 'AttorneyLegacyTask' });

      rowObjects = rowObjects.concat(additionalRows);
      wrapper = mount(
        <QueueTable columns={columns} rowObjects={rowObjects} summary="test table" slowReRendersAreOk />
      );

      wrapper.instance().updateFilteredByList({ type: ['AttorneyLegacyTask'] });
      wrapper.update();

      expect(wrapper.find('tr')).to.have.length(3);
    });

    it('updates current page', () => {
      wrapper = mount(
        <QueueTable columns={columns} rowObjects={rowObjects} summary="test table" slowReRendersAreOk />
      );

      wrapper.instance().updateCurrentPage(1);
      wrapper.update();

      expect(wrapper.instance().state.currentPage).to.equal(1);
    });

    it('paginates table data', () => {
      wrapper = mount(
        <QueueTable columns={columns} rowObjects={rowObjects} summary="test table" slowReRendersAreOk />
      );

      const paginatedData = wrapper.instance().paginateData(rowObjects);

      expect(paginatedData).to.have.length(1);
      expect(rowObjects).to.include(paginatedData[0][0]);
    });
  });
});
