import React from 'react';
import TestSeedsApp from 'app/testSeeds/pages/TestSeedsApp';
import { mount } from 'enzyme';

describe('render Test Seeds Application', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders Test Seeds App', () => {

    let wrapper = mount(
      <TestSeedsApp />
    );

    wrapper.update();

    expect(wrapper.find('#run_custom_seeds').exists()).toBeTruthy();
    expect(wrapper.find('#run_seeds').exists()).toBeTruthy();
  });
});

