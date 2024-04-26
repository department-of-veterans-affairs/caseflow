import React from 'react';
import {waitFor} from '@testing-library/react';
import CustomSeeds from 'app/testSeeds/components/CustomSeeds';
import { mount } from 'enzyme';
import COPY from '../../../../COPY';
import CUSTOM_SEEDS from '../../../../constants/CUSTOM_SEEDS';

describe('Scenario Seeds', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders Scenario Seeds', () => {

    let wrapper = mount(
      <CustomSeeds />
    );

    expect(Object.keys(CUSTOM_SEEDS).length).toEqual(4);

    let inputField = wrapper.find('input[id="case-count-seed-ama-aod-hearing"]');
    let inputField2 = wrapper.find('input[id="days-ago-seed-ama-aod-hearing"]');
    let inputField3= wrapper.find('input[id="css-id-seed-ama-aod-hearing"]');

    // Calls simulate change to set value outside of min/max range
    waitFor(() => inputField.simulate('change', 2));
    waitFor(() => inputField2.simulate('change', 90));
    waitFor(() => inputField3.simulate('change', 'BVADWISE'));

    wrapper.update();

    waitFor(() => expect(inputField.prop('value').toBe(2)));

    expect(wrapper.find('#run_custom_seeds').text()).toContain(COPY.TEST_SEEDS_CUSTOM_SEEDS);
  });
});

