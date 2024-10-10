import React from 'react';
import { mount } from 'enzyme';
import CaseDistributionTest from '../../../../app/caseDistribution/test';
import ApiUtil from '../../../../app/util/ApiUtil';
import { MemoryRouter } from 'react-router-dom';

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
    mockPost.mockResolvedValue({
      body: { seeds_added: 4094 },
    });

    const successResponse = 'Successfully Completed Full Suite Seed Job.'
    const instance = wrapper.find(CaseDistributionTest).instance();

    await instance.reseedGenericFullSuiteAppealsSeeds();

    wrapper.update();

    expect(mockPost).toHaveBeenCalledWith('/case_distribution_levers_tests/run_full_suite_seeds');

    expect(wrapper.find(CaseDistributionTest).state('isReseedingOptionalSeeds')).toBe(false);
    expect(wrapper.find(CaseDistributionTest).state('showAlert')).toBe(true);
    expect(wrapper.find(CaseDistributionTest).state('alertMsg')).toContain(successResponse);
  });

  it('should set state correctly on API error', async () => {
    const errorMessage = 'API Error';

    ApiUtil.post.mockRejectedValueOnce(errorMessage);

    const instance = wrapper.find(CaseDistributionTest).instance();

    await instance.reseedGenericFullSuiteAppealsSeeds();

    expect(wrapper.find(CaseDistributionTest).state('isReseedingOptionalSeeds')).toBe(false);
    expect(wrapper.find(CaseDistributionTest).state('showAlert')).toBe(true);
    expect(wrapper.find(CaseDistributionTest).state('alertMsg')).toBe(errorMessage);

    const caughtError = new Error(errorMessage);

    expect(caughtError).toBeInstanceOf(Error);
  });
});
