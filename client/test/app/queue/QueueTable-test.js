import React from 'react';
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

      expect(wrapper.find('table')).toHaveLength(1);
      expect(wrapper.find('tr')).toHaveLength(rowCount);
      expect(wrapper.find('td')).toHaveLength(cellCount);
      expect(wrapper.find('th')).toHaveLength(headerCount);

      expect(
        wrapper.
          find('td').
          last().
          text()
      ).toBe('EstablishClaim');
    });

    it('updates filteredByList', () => {
      const additionalRows = createTask(2, { type: 'AttorneyLegacyTask' });

      rowObjects = rowObjects.concat(additionalRows);
      wrapper = mount(
        <QueueTable columns={columns} rowObjects={rowObjects} summary="test table" slowReRendersAreOk />
      );

      wrapper.instance().updateFilteredByList({ type: ['AttorneyLegacyTask'] });
      wrapper.update();

      expect(wrapper.instance().state.filteredByList.type).toEqual(expect.arrayContaining(['AttorneyLegacyTask']));
    });

    it('displays the correctly filtered data', () => {
      const additionalRows = createTask(2, { type: 'AttorneyLegacyTask' });

      rowObjects = rowObjects.concat(additionalRows);
      wrapper = mount(
        <QueueTable columns={columns} rowObjects={rowObjects} summary="test table" slowReRendersAreOk />
      );

      wrapper.instance().updateFilteredByList({ type: ['AttorneyLegacyTask'] });
      wrapper.update();

      expect(wrapper.find('tr')).toHaveLength(3);
    });

    it('updates current page', () => {
      wrapper = mount(
        <QueueTable columns={columns} rowObjects={rowObjects} summary="test table" slowReRendersAreOk />
      );

      wrapper.instance().updateCurrentPage(1);
      wrapper.update();

      expect(wrapper.instance().state.currentPage).toBe(1);
    });

    it('paginates table data', () => {
      wrapper = mount(
        <QueueTable columns={columns} rowObjects={rowObjects} summary="test table" slowReRendersAreOk />
      );

      const paginatedData = wrapper.instance().paginateData(rowObjects);

      expect(paginatedData).toHaveLength(1);
      expect(rowObjects).toEqual(expect.arrayContaining([paginatedData[0][0]]));
    });
  });
});
