import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';

import Alert from '../../app/components/Alert';

describe('Alert', () => {
  it('renders', () => {
    let title = "My Error";
    let message = "There was an error";
    const wrapper = shallow(
      <Alert type="error" title={title} message={message}/>
    );
    expect(wrapper.find('.usa-alert')).to.have.length(1);
    expect(wrapper.find('.usa-alert-heading').text()).to.eq(title);
    expect(wrapper.find('.usa-alert-text').text()).to.eq(message);
  });
});
