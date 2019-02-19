import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import TableFilter from '../../../app/components/TableFilter';
import { createTask } from '../../factory';

describe('TableFilter', () => {
  let wrapper;
  let props;

  beforeEach(() => {
    props = {
      columnName: 'type',
      filteredByList: {},
      label: 'type',
      tableData: createTask(3),
      valueName: 'type',
      updateFilters: () => ({}),
      toggleDropdownFilterVisibility: () => ({})
    };
  });

  context('renders', () => {
    it('works', () => {
      wrapper = mount(
        <TableFilter {...props} />
      );

      expect(wrapper.find('FilterIcon')).to.have.length(1);
    });

    it('displays filter dropdown when isDropdownFilterOpen is true', () => {
      wrapper = mount(
        <TableFilter
          {...props}
          isDropdownFilterOpen />
      );

      expect(wrapper.find('NewDropdownFilter')).to.have.length(1);
    });

    it('does not display filter dropdown when isDropdownFilterOpen is false', () => {
      wrapper = mount(
        <TableFilter
          {...props}
          isDropdownFilterOpen={false} />
      );

      expect(wrapper.find('NewDropdownFilter')).to.have.length(0);
    });

    it('generates the correct list of unique filter options', () => {
      const additionalData = createTask(2, { type: 'AttorneyLegacyTask' });

      props.tableData = props.tableData.concat(additionalData);

      wrapper = mount(
        <TableFilter
          {...props}
          isDropdownFilterOpen />
      );

      expect(wrapper.find('input[type="checkbox"]')).to.have.length(2);
    });

    it('adds additional filters to the correct array in the filteredByList', () => {
      wrapper = mount(
        <TableFilter
          {...props}
          isDropdownFilterOpen={false} />
      );

      wrapper.instance().updateSelectedFilter('AttorneyLegacyTask', 'type');
      wrapper.update();

      expect(props.filteredByList.type).to.include('AttorneyLegacyTask');

      wrapper.instance().updateSelectedFilter('EstablishClaim', 'type');
      wrapper.update();

      expect(props.filteredByList.type).to.include('EstablishClaim');
      expect(props.filteredByList.type).to.have.length(2);
    });

    it('removes additional filters from the correct array in the filteredByList', () => {
      wrapper = mount(
        <TableFilter
          {...props}
          isDropdownFilterOpen={false} />
      );

      wrapper.instance().updateSelectedFilter('AttorneyLegacyTask', 'type');
      wrapper.instance().updateSelectedFilter('EstablishClaim', 'type');
      wrapper.update();

      wrapper.instance().updateSelectedFilter('AttorneyLegacyTask', 'type');
      wrapper.update();

      expect(props.filteredByList.type).to.include('EstablishClaim');
      expect(props.filteredByList.type).to.not.include('AttorneyLegacyTask');
    });

    it('clearFilteredByList clears filters', () => {
      wrapper = mount(
        <TableFilter
          {...props}
          isDropdownFilterOpen={false} />
      );

      wrapper.instance().updateSelectedFilter('AttorneyLegacyTask', 'type');
      wrapper.instance().updateSelectedFilter('EstablishClaim', 'type');
      wrapper.update();

      wrapper.instance().clearFilteredByList('type');
      wrapper.update();

      expect(props.filteredByList.type).to.have.length(0);
    });
  });
});
