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
    mockPost.mockResolvedValue({
      body: { seeds_added: 4094 },
    });

    const instance = wrapper.find(CaseDistributionTest).instance();

    await instance.reseedGenericFullSuiteAppealsSeeds();

    wrapper.update();

    expect(mockPost).toHaveBeenCalledWith('/case_distribution_levers_tests/run_full_suite_seeds');

    expect(wrapper.find(CaseDistributionTest).state('isReseedingOptionalSeeds')).toBe(false);
    expect(wrapper.find(CaseDistributionTest).state('showAlert')).toBe(true);
    expect(wrapper.find(CaseDistributionTest).state('alertMsg')).toContain(
      COPY.TEST_RESEED_GENERIC_FULL_SUITE_APPEALS_ALERTMSG.replace('{count}', '4094')
    );
  });

  it('calls the reseedGenericFullSuiteAppealsSeeds function and handles error', async () => {
    const errorMessage = 'API Error';

    mockPost.mockRejectedValue((errorMessage));

    const instance = wrapper.find(CaseDistributionTest).instance();

    await instance.reseedGenericFullSuiteAppealsSeeds();

    wrapper.update();

    expect(mockPost).toHaveBeenCalledWith('/case_distribution_levers_tests/run_full_suite_seeds');

    expect(wrapper.find(CaseDistributionTest).state('isReseedingOptionalSeeds')).toBe(false);
    expect(wrapper.find(CaseDistributionTest).state('showAlert')).toBe(true);
    expect(wrapper.find(CaseDistributionTest).state('alertMsg')).toBe(errorMessage);
    expect(wrapper.find(CaseDistributionTest).state('alertType')).toBe('error');
  });
});
