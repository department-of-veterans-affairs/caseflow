import React from 'react';
import {fireEvent, waitFor, screen} from '@testing-library/react';
import ScenarioSeeds from 'app/testSeeds/components/ScenarioSeeds';
import { mount } from 'enzyme';
import COPY from '../../../../COPY';
import TEST_SEEDS from '../../../../constants/TEST_SEEDS';
import userEvent from '@testing-library/user-event';

describe('Scenario Seeds', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders Scenario Seeds', () => {

    let wrapper = mount(
      <ScenarioSeeds />
    );

    expect(Object.keys(TEST_SEEDS).length).toEqual(2);

    let inputField = wrapper.find('input[id="count-aod-seeds"]');

    // Calls simulate change to set value outside of min/max range
    waitFor(() => inputField.simulate('change', 2));

    wrapper.update();

    waitFor(() => expect(inputField.prop('value').toBe(2)));

    expect(wrapper.find('#run_seeds').text()).toContain(COPY.TEST_SEEDS_RUN_SEEDS);
  });

  // it('renders Scenario Seeds with button', async () => {
  //   let wrapper = mount(
  //     <ScenarioSeeds />
  //   );

  //   let buttonField = wrapper.find('#button-Run-Demo-Aod-Seeds');
  //   expect(buttonField.text()).toContain('Run Demo Aod Seeds')
  //   expect(buttonField.props().text()).to.be.eql('Run Demo Aod Seeds');

  //   await fireEvent.click(buttonField);

  //   const seedButton = screen.getByText('Run Demo Aod Seeds');

  //   userEvent.click(seedButton);


  //   waitFor(() => expect(buttonField.text()).toContain('Reseed Run Demo Aod Seeds'));
  // })
});

