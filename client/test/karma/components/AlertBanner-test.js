import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import AlertBanner from '../../../app/components/AlertBanner';

describe('AlertBanner', () => {
  it('shows info banner', () => {
    let wrapper = mount(<AlertBanner title="Info banner" type="info">
      This shows an info banner.
    </AlertBanner>);

    expect(wrapper.find('.usa-alert-info')).to.have.length(1);
  });
  it('shows warning banner', () => {
    let wrapper = mount(<AlertBanner title="Warning banner" type="warning">
      This shows a warning banner.
    </AlertBanner>);

    expect(wrapper.find('.usa-alert-warning')).to.have.length(1);
  });
  it('shows error banner', () => {
    let wrapper = mount(<AlertBanner title="Error banner" type="error">
      This shows a error banner.
    </AlertBanner>);

    expect(wrapper.find('.usa-alert-error')).to.have.length(1);
  });
  it('shows success banner', () => {
    let wrapper = mount(<AlertBanner title="Success banner" type="success">
      This shows a success banner.
    </AlertBanner>);

    expect(wrapper.find('.usa-alert-success')).to.have.length(1);
  });
});
