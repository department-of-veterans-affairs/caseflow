import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';

import Table from '../../app/components/Table';
import { createTask } from '../factory';

describe('Table', () => {
  let columns;
  let rowObjects;
  let wrapper;

  beforeEach(() => {
    columns = [
      { header: 'First',
        valueFunction: () => "fizz" },
      { header: 'Second',
        valueFunction: () => "buzz" },
      { header: 'Second',
        valueName: "type" }
    ];

    rowObjects = createTask(3);
  });

  context('renders', () => {
    it('works', () => {
      wrapper = shallow(
        <Table columns={columns} rowObjects={rowObjects} summary="test table"/>
      );
      let headerCount = 3;
      let rowCount = 4;
      let cellCount = 9;

      expect(wrapper.find('table')).to.have.length(1);
      expect(wrapper.find('th')).to.have.length(headerCount);
      expect(wrapper.find('tr')).to.have.length(rowCount);
      expect(wrapper.find('td')).to.have.length(cellCount);
      expect(
        wrapper.
        find('td').
        last().
        text()
      ).to.eq('EstablishClaim');
    });
  });
});
