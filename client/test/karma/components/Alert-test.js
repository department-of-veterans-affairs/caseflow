import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';

import Alert from '../../../app/components/Alert';

describe('Alert', () => {
  let title;
  let message;
  let wrapper;

  beforeEach(() => {
    title = 'My Error';
    message = 'There was an error';
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

  context('show correct alert type', () => {
    it('shows info banner', () => {
      wrapper = shallow(<Alert title="Info banner" type="info">
        This shows an info banner.
      </Alert>);

      expect(wrapper.find('.usa-alert-info')).to.have.length(1);
    });

    it('shows warning banner', () => {
      wrapper = shallow(<Alert title="Warning banner" type="warning">
        This shows a warning banner.
      </Alert>);

      expect(wrapper.find('.usa-alert-warning')).to.have.length(1);
    });

    it('shows error banner', () => {
      wrapper = shallow(<Alert title="Error banner" type="error">
        This shows a error banner.
      </Alert>);

      expect(wrapper.find('.usa-alert-error')).to.have.length(1);
    });

    it('shows success banner', () => {
      wrapper = shallow(<Alert title="Success banner" type="success">
        This shows a success banner.
      </Alert>);

      expect(wrapper.find('.usa-alert-success')).to.have.length(1);
    });
  });
});
