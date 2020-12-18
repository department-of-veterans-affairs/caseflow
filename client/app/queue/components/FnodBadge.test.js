import React from 'react';
import FnodBadge from 'app/queue/components/FnodBadge';
import { mount } from 'enzyme';

describe('FnodBadge', () => {
  const defaultAppeal = {
    veteran_appellant_deceased: true,
    date_of_death: '2019-03-17'
  };

  const setupFnodBadge = () => {
    return mount(
      <FnodBadge
        appeal={defaultAppeal}
      />
    );
  };

  it('renders correctly', () => {
    const component = setupFnodBadge();

    expect(component).toMatchSnapshot();
  });
});
