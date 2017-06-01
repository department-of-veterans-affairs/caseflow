import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';

import { PdfUIPageNumInput } from '../../../app/reader/PdfUIPageNumInput';

describe('PdfUIPageNumInput', () => {
  let wrapper;

  context('input value', () => {
    it('sets input value correctly', () => {
      const INPUT_VALUE = 3;

      wrapper = shallow(
        <PdfUIPageNumInput
          currentPage={1}
          numPages={4}
          docId={1}
          jumpToPage={ () => {
            return null;
          }}
        />,
        { lifecycleExperimental: true }
      );

      const input = wrapper.find('input');

      wrapper.find('input').simulate('change', { target: { value: INPUT_VALUE } });
      input.simulate('keypress', {
        key: 'Enter',
        target: { value: INPUT_VALUE }
      });
      expect(wrapper.find('input').props().value).to.eq();
    });

    it('sets input value reset to current page if invalid', () => {
      const input = wrapper.find('input');

      wrapper.setProps({ currentPage: 3 });
      input.simulate('change', { target: { value: 100 } });
      input.simulate('keypress', {
        key: 'Enter',
        target: { value: 100 }
      });

      expect(input.props().value).to.eq(3);
    });
  });
});
