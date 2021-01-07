import React from 'react';
import FnodBanner from 'app/queue/components/FnodBanner';
import { mount } from 'enzyme';
import moment from 'moment';

describe('FnodBanner', () => {
  const defaultAppeal = {
    veteran_appellant_deceased: true,
    date_of_death: '2019-03-17',
    veteranFullName: 'Jane Doe'
  };

  const setupFnodBanner = () => {
    return mount(
      <FnodBanner
        appeal={defaultAppeal}
      />
    );
  };

  it('renders correctly', () => {
    const component = setupFnodBanner();

    expect(component).toMatchSnapshot();
  });

  it('displays date of death', () => {
    const component = setupFnodBanner();

    const alertText = component.find('.usa-alert-text');

    expect(alertText.html()).toContain(moment(defaultAppeal.date_of_death).format('MM/DD/YYYY'));
  });

  it('displays Veteran appellant\'s full name', () => {
    const component = setupFnodBanner();

    const alertText = component.find('.usa-alert-text');

    expect(alertText.html()).toContain(defaultAppeal.veteranFullName);
  });
});
