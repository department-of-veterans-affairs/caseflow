import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import TestSeeds from './TestSeeds';
import ApiUtil from '../util/ApiUtil';
import { mount } from 'enzyme';
// import '@testing-library/jest-dom/extend-expect';

jest.mock('../util/ApiUtil');

describe('TestSeeds component', () => {

  it('handles seed runs correctly', async () => {
    const inputData = { target: { value: '2' } };
    let wrapper = mount(
      <TestSeeds/>
    );

    let inputField = wrapper.find('input[id="count-aod-seeds"]');
    waitFor(() => inputField.simulate('change', inputData));
    wrapper.update();
    waitFor(() => expect(inputField.prop('value').toBe(2)));


    let buttonField = wrapper.find('#button-Run-Demo-Aod-Seeds');
    // expect(buttonField.text()).to.be.eql('Run Demo Aod Seeds')
    // expect(buttonField.props().text()).to.be.eql('Run Demo Aod Seeds');

    // await buttonField.prop('onClick')();
    // buttonField.simulate('click');

    // fireEvent.click(buttonField);


    waitFor(() => {
      expect(buttonField.prop('className')).toMatch(/cf-submit usa-button/);
    });
  });
});
