import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';

import Table from '../../app/components/Table';

describe('Table', () => {
  let buildRowValues;
  let headers;
  let values;
  let wrapper;

  beforeEach(() => {
    buildRowValues = (obj) => ['fizz', 'buzz', obj.val];
    headers = ['First', 'Second', 'Third'];
    values = [
      { id: 1, val: 'foo' },
      { id: 2, val: 'bar' },
      { id: 3, val: 'baz' }
    ];
  });

  context('renders', () => {
    it('works', () => {
      wrapper = shallow(
        <Table headers={headers} values={values} buildRowValues={buildRowValues}/>
      );
      expect(wrapper.find('table')).to.have.length(1);
      expect(wrapper.find('th')).to.have.length(3);
      expect(wrapper.find('tr')).to.have.length(4);
      expect(wrapper.find('td')).to.have.length(9);
      expect(wrapper.find('td').last().text()).to.eq('baz');
    });
  });
});
