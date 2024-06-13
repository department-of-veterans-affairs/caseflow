// import React from 'react';
// import { render, fireEvent, waitFor } from '@testing-library/react';
// import ScenarioSeeds from 'app/testSeeds/components/ScenarioSeeds';
// import TEST_SEEDS from '../../../../constants/TEST_SEEDS';
// import ApiUtil from 'app/util/ApiUtil';

// jest.mock('app/util/ApiUtil', () => ({
//   post: jest.fn()
// }));

// describe('Scenario Seeds', () => {

//   beforeEach(() => {
//     // Reset mock implementation before each test
//     ApiUtil.post.mockReset();
//   });

//   afterEach(() => {
//     jest.clearAllMocks();
//   });

//   const component = new ScenarioSeeds();

//   it('should render input fields and buttons for each seed type', () => {
//     const { getByLabelText, getByText } = render(<ScenarioSeeds />);
//     // Check if input fields and buttons are rendered for each seed type
//     Object.keys(TEST_SEEDS).forEach((type) => {
//       const input = getByLabelText(`count-${type}`);
//       const button = getByText(`Run Demo ${component.formatSeedName(type)}`);
//       expect(input).toBeInTheDocument();
//       expect(button).toBeInTheDocument();
//     });
//   })

//   it('should update input value when user types', () => {
//     const { getByLabelText } = render(<ScenarioSeeds />);
//     const seed_aod_type = Object.keys(TEST_SEEDS)[0];
//     const input = getByLabelText(`count-${seed_aod_type}`);

//     fireEvent.change(input, { target: { value: '10' } });
//     expect(input.value).toBe('10');
//   });

//   it('should make API call when button is clicked', async () => {
//     ApiUtil.post.mockResolvedValueOnce({ data: 'Success' });
//     const { getByText, getByLabelText } = render(<ScenarioSeeds />);
//     const seed_aod_type = Object.keys(TEST_SEEDS)[0];
//     const input = getByLabelText(`count-${seed_aod_type}`);
//     const button = getByText(`Run Demo ${component.formatSeedName(seed_aod_type)}`);

//     fireEvent.change(input, { target: { value: '10' } });
//     fireEvent.click(button);

//     expect(ApiUtil.post).toHaveBeenCalledWith(`/seeds/run-demo?seed_type=${seed_aod_type}&seed_count=10`);

//     // Wait for API call to resolve
//     await waitFor(() => {
//       expect(ApiUtil.post).toHaveBeenCalledTimes(1);
//     });
//   });

//   it('should handle API call error', async () => {
//     // Spy on console.warn
//     const consoleWarnSpy = jest.spyOn(console, 'warn');

//     ApiUtil.post.mockRejectedValueOnce(new Error('API Error'));
//     const { getByText, getByLabelText } = render(<ScenarioSeeds />);
//     const seed_aod_type = Object.keys(TEST_SEEDS)[0];
//     const input = getByLabelText(`count-${seed_aod_type}`);
//     const button = getByText(`Run Demo ${component.formatSeedName(seed_aod_type)}`);

//     fireEvent.change(input, { target: { value: '10' } });
//     fireEvent.click(button);

//     expect(ApiUtil.post).toHaveBeenCalledWith(`/seeds/run-demo?seed_type=${seed_aod_type}&seed_count=10`);

//     // Wait for API call to reject
//     await waitFor(() => {
//       expect(ApiUtil.post).toHaveBeenCalledTimes(1);
//     });

//     // Check if error message is displayed
//     expect(consoleWarnSpy).toHaveBeenCalledWith(new Error('API Error'));
//   });
// });

