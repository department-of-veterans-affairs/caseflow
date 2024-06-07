import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import CustomSeeds from 'app/testSeeds/components/CustomSeeds';
import CUSTOM_SEEDS from '../../../../constants/CUSTOM_SEEDS';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('app/util/ApiUtil', () => ({
  post: jest.fn()
}));

describe('Custom Seeds', () => {

  beforeEach(() => {
    // Reset mock implementation before each test
    ApiUtil.post.mockReset();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  const seedTypes = Object.keys(CUSTOM_SEEDS);

  it('should render input fields and buttons for each seed type', () => {
    const { getByLabelText, container } = render(<CustomSeeds />);

    // Check if input fields and buttons are rendered for each seed type
    seedTypes.forEach((type) => {
      const caseCountInput = getByLabelText(`seed-count-${type}`);
      const daysAgoInput = getByLabelText(`days-ago-${type}`);
      const cssIdInput = getByLabelText(`css-id-${type}`);
      const button = container.querySelector(`#btn-${type}`);

      expect(caseCountInput).toBeInTheDocument();
      expect(daysAgoInput).toBeInTheDocument();
      expect(cssIdInput).toBeInTheDocument();
      expect(button).toBeInTheDocument();
    });
  });

  it('should update state when input values change', () => {
    const { getByLabelText } = render(<CustomSeeds />);
    const first_seed = seedTypes[0];
    const caseCountInput = getByLabelText(`seed-count-${first_seed}`);
    const daysAgoInput = getByLabelText(`days-ago-${first_seed}`);
    const cssIdInput = getByLabelText(`css-id-${first_seed}`);

    fireEvent.change(caseCountInput, { target: { value: '10' } });
    fireEvent.change(daysAgoInput, { target: { value: '5' } });
    fireEvent.change(cssIdInput, { target: { value: '12345' } });

    expect(caseCountInput.value).toBe('10');
    expect(daysAgoInput.value).toBe('5');
    expect(cssIdInput.value).toBe('12345');
  });

  it('should make API call when button is clicked', async () => {
    ApiUtil.post.mockResolvedValueOnce({ data: 'Success' });

    const { container, getByLabelText } = render(<CustomSeeds />);
    const first_seed = seedTypes[0];
    const caseCountInput = getByLabelText(`seed-count-${first_seed}`);
    const daysAgoInput = getByLabelText(`days-ago-${first_seed}`);
    const cssIdInput = getByLabelText(`css-id-${first_seed}`);
    const button = container.querySelector(`#btn-${first_seed}`);

    fireEvent.change(caseCountInput, { target: { value: '10' } });
    fireEvent.change(daysAgoInput, { target: { value: '5' } });
    fireEvent.change(cssIdInput, { target: { value: 'BVADWISE' } });

    // Find the button in the same row as the input fields
    const row = button.closest('tr');
    // const createButton = within(row).getByText('Create');

    fireEvent.click(button);

    expect(ApiUtil.post).toHaveBeenCalledWith(`/seeds/run-demo`, {
      data: { seed_type: first_seed, seed_count: 10, days_ago: 5, judge_css_id: 'BVADWISE' }
    });

    // Wait for API call to resolve
    await waitFor(() => {
      expect(ApiUtil.post).toHaveBeenCalledTimes(1);
    });
  });

  it('should handle API call error', async () => {
    const consoleWarnSpy = jest.spyOn(console, 'warn');

    ApiUtil.post.mockRejectedValueOnce(new Error('API Error'));
    const { container, getByLabelText } = render(<CustomSeeds />);
    const first_seed = seedTypes[0];
    const caseCountInput = getByLabelText(`seed-count-${first_seed}`);
    const daysAgoInput = getByLabelText(`days-ago-${first_seed}`);
    const cssIdInput = getByLabelText(`css-id-${first_seed}`);
    const button = container.querySelector(`#btn-${first_seed}`);

    fireEvent.change(caseCountInput, { target: { value: '10' } });
    fireEvent.change(daysAgoInput, { target: { value: '5' } });
    fireEvent.change(cssIdInput, { target: { value: 'BVADWISE' } });
    fireEvent.click(button);

    expect(ApiUtil.post).toHaveBeenCalledWith(`/seeds/run-demo`, {
      data: { seed_type: first_seed, seed_count: 10, days_ago: 5, judge_css_id: 'BVADWISE' }
    });

    // Wait for API call to reject
    await waitFor(() => {
      expect(ApiUtil.post).toHaveBeenCalledTimes(1);
    });

    // Check if error message is displayed
    expect(consoleWarnSpy).toHaveBeenCalledWith(new Error('API Error'));
  });
});

