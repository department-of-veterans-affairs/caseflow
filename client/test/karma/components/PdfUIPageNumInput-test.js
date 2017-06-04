import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import TextField from '../../../app/components/TextField';

import { PdfUIPageNumInput } from '../../../app/reader/PdfUIPageNumInput';

describe('PdfUIPageNumInput', () => {
  let wrapper;

  context('input value', () => {
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

    it('sets input value correctly', () => {
      const INPUT_VALUE = 3;

      const input = wrapper.find(TextField).dive().
        find('input');

      input.simulate('change', { target: { value: INPUT_VALUE } });
      input.simulate('keypress', {
        key: 'Enter',
        target: { value: INPUT_VALUE }
      });
      expect(input.props().value).to.eq(INPUT_VALUE);
    });
  });

  it('sets input value reset to current page if invalid', () => {

    wrapper.setProps({ currentPage: 3 });
    const input = wrapper.find(TextField).dive().
      find('input');

    input.simulate('change', { target: { value: 100 } });
    input.simulate('keypress', {
      key: 'Enter',
      target: { value: 100 }
    });
    expect(input.props().value).to.eq(3);
  });
});
