import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import Modal from '../../app/components/Modal';

describe('Modal', () => {
  let wrapper;

  context('renders', () => {
    it('works', () => {
      wrapper = mount(
        <Modal
        buttons={[
          { classNames: ["test-class"],
            name: 'Button 1'
          },
          { classNames: ["test-class"],
            name: 'Button 2'
          }
        ]}
        visible={true}
        title="Test Title">
          Test Content
        </Modal>
      );
      let buttonCount = 2;

      expect(wrapper.find('.cf-modal')).to.have.length(1);
      expect(wrapper.find('.test-class')).to.have.length(buttonCount);
    });
  });
});
