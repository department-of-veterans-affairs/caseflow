import React from 'react';
import { mount } from 'enzyme';
import CaseDistributionTest from '../../../../app/caseDistribution/test';
import ApiUtil from '../../../../app/util/ApiUtil';
import { MemoryRouter } from 'react-router-dom';
import COPY from '../../../../COPY';

jest.mock('app/util/ApiUtil');

describe('CaseDistributionTest Component reseedGenericFullSuiteAppealsSeeds', () => {
  let wrapper;
  const mockPost = jest.fn();

  beforeEach(() => {
    ApiUtil.post = mockPost;
    wrapper = mount(
      <MemoryRouter>
        <CaseDistributionTest />
      </MemoryRouter>
    );
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  it('calls the reseedGenericFullSuiteAppealsSeeds function and handles success', async () => {
    // Mock the successful API response
    mockPost.mockResolvedValue({
      body: { seeds_added: 4094 },
    });

    // Directly invoke the reseedGenericFullSuiteAppealsSeeds function
    const instance = wrapper.find(CaseDistributionTest).instance();
    instance.reseedGenericFullSuiteAppealsSeeds();

    // Wait for the state update
    await new Promise(setImmediate);
    wrapper.update();

    // Check that the API was called with the correct URL
    expect(mockPost).toHaveBeenCalledWith('/test/optional_seed');

    // Verify the expected state changes
    expect(wrapper.find(CaseDistributionTest).state('isReseedingOptionalSeeds')).toBe(false);
    expect(wrapper.find(CaseDistributionTest).state('showAlert')).toBe(true);
    expect(wrapper.find(CaseDistributionTest).state('alertMsg')).toContain(
      COPY.TEST_RESEED_GENERIC_FULL_SUITE_APPEALS_ALERTMSG.replace('{count}', '4094')
    );
  });

  it('calls the reseedGenericFullSuiteAppealsSeeds function and handles error', async () => {
    // Mock a failed API response
    const errorMessage = 'API Error';

    mockPost.mockRejectedValue((errorMessage));

    // Directly invoke the reseedGenericFullSuiteAppealsSeeds function
    const instance = wrapper.find(CaseDistributionTest).instance();

    instance.reseedGenericFullSuiteAppealsSeeds();

    // Wait for the state update
    await new Promise(setImmediate);
    wrapper.update();

    // Check that the API was called with the correct URL
    expect(mockPost).toHaveBeenCalledWith('/test/optional_seed');

    // Verify the expected state changes after error
    expect(wrapper.find(CaseDistributionTest).state('isReseedingOptionalSeeds')).toBe(false);
    expect(wrapper.find(CaseDistributionTest).state('showAlert')).toBe(true);
    expect(wrapper.find(CaseDistributionTest).state('alertMsg')).toBe(errorMessage);
    expect(wrapper.find(CaseDistributionTest).state('alertType')).toBe('error');
  });
});
