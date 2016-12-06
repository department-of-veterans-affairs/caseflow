import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';

import Alert from '../../app/components/Alert';

describe('Alert', () => {
  let title;
  let message;
  let wrapper;

  beforeEach(() => {
    title = "My Error";
    message = "There was an error";
  });

  context('role attribute', () => {
    it('sets it to `alert` if error type', () => {
      wrapper = shallow(
        <Alert type="error" title={title} message={message}/>
      );
      expect(wrapper.instance().props.type).to.eq('error');
      expect(wrapper.find('.usa-alert').prop('role')).to.eq('alert');
    });

    it('does not set role attribute if not error type', () => {
      wrapper = shallow(
        <Alert type="success" title={title} message={message}/>
      );
      expect(wrapper.find('.usa-alert').prop('role')).to.not.eq('alert');
    });
  });
});
