import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';

import { PdfUIPageNumInput } from '../../../app/reader/PdfUIPageNumInput';

describe.only('PdfUIPageNumInput', () => {
  let wrapper;

  context('input value', () => {
    it('sets input value correctly', () => {
      wrapper = shallow(
        <PdfUIPageNumInput
          currentPage={1}
          numPages={4}
          docId={1}
          jumpToPage={ () => {} }
        />,  { lifecycleExperimental: true }
      );

      const input = wrapper.find('input');

      wrapper.find('input').simulate('change', { target: { value: 3 } });
      input.simulate('keypress', {
        key: 'Enter',
        target: { value: 3 }
      });
      expect(wrapper.find('input').props().value).to.eq(3);
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
