import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import TextField from '../../../app/components/TextField';

import { PdfUIPageNumInput } from '../../../app/reader/PdfUIPageNumInput';

describe('PdfUIPageNumInput', () => {
  let wrapper;

  const getInput = () => wrapper.find(TextField).dive().find('input') 

  context('input value', () => {
    wrapper = shallow(
      <PdfUIPageNumInput
        currentPage={1}
        numPages={4}
        docId={1}
        jumpToPage={() => null}
      />,
      { lifecycleExperimental: true }
    );

    it('sets input value correctly', () => {
      const inputValue = 3;

      const input = getInput();

      input.simulate('keypress', {
        key: 'Enter',
        target: { value: inputValue }
      });
      wrapper.update()

      expect(getInput().props().value).to.eq(inputValue);
    });
  });

  it('sets input value reset to current page if invalid', () => {

    wrapper.setProps({ currentPage: 3 });
    const input = getInput();

    input.simulate('keypress', {
      key: 'Enter',
      target: { value: 100 }
    });
    wrapper.update()
    
    expect(getInput().props().value).to.eq(3);
  });
});
