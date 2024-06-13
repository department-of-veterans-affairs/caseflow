import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import CustomSeeds from 'app/testSeeds/components/CustomSeeds';
import CUSTOM_SEEDS from '../../../../constants/CUSTOM_SEEDS';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/testSeeds/reducers/root';
import { addCustomSeed } from 'app/testSeeds/reducers/seeds/seedsActions';
import thunk from 'redux-thunk';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('app/util/ApiUtil', () => ({
  get: jest.fn()
}));

describe('Custom Seeds', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk)
  );

  afterEach(() => {
    jest.clearAllMocks();
  });

  const seedTypes = Object.keys(CUSTOM_SEEDS);

  it('renders Custom Seeds correctly and check the buttons within the page', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        <CustomSeeds />
      </Provider>
    );
    expect(screen.getByText('Download Appeals Ready to Distribute CSV')).toBeInTheDocument();
    expect(screen.getByText('Upload Test Cases CSV')).toBeInTheDocument();
    expect(screen.getByText('Download Template')).toBeInTheDocument();
    expect(screen.getByText('Reset all appeals')).toBeInTheDocument();
    expect(screen.getByText('reset form')).toBeInTheDocument();
  });

  it('should render input fields and buttons for each seed type', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        <CustomSeeds />
      </Provider>
    );

    // Check if input fields and buttons are rendered for each seed type
    seedTypes.forEach((type,index) => {
      const caseCountInput = screen.getByLabelText(`seed-count-${type}`);
      const daysAgoInput = screen.getByLabelText(`days-ago-${type}`);
      const cssIdInput = screen.getByLabelText(`css-id-${type}`);
      const button = screen.getAllByRole('button')[index];

      expect(caseCountInput).toBeInTheDocument();
      expect(daysAgoInput).toBeInTheDocument();
      expect(cssIdInput).toBeInTheDocument();
      expect(button).toBeInTheDocument();
    });
  });

  it('should update state when input values change', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        <CustomSeeds />
      </Provider>
    );
    const first_seed = seedTypes[0];
    const caseCountInput = screen.getByLabelText(`seed-count-${first_seed}`);
    const daysAgoInput = screen.getByLabelText(`days-ago-${first_seed}`);
    const cssIdInput = screen.getByLabelText(`css-id-${first_seed}`);

    fireEvent.change(caseCountInput, { target: { value: '10' } });
    fireEvent.change(daysAgoInput, { target: { value: '5' } });
    fireEvent.change(cssIdInput, { target: { value: '12345' } });

    expect(caseCountInput.value).toBe('10');
    expect(daysAgoInput.value).toBe('5');
    expect(cssIdInput.value).toBe('12345');
  });

  it('should show the preview for input entries and reset form', () => {
    const store = getStore();

    const { container } = render(
      <Provider store={store}>
        <CustomSeeds />
      </Provider>
    );

    const first_seed = seedTypes[0];
    const caseCountInput = screen.getByLabelText(`seed-count-${first_seed}`);
    const daysAgoInput = screen.getByLabelText(`days-ago-${first_seed}`);
    const cssIdInput = screen.getByLabelText(`css-id-${first_seed}`);
    const button = container.querySelector(`#btn-${first_seed}`);

    fireEvent.change(caseCountInput, { target: { value: '10' } });
    fireEvent.change(daysAgoInput, { target: { value: '5' } });
    fireEvent.change(cssIdInput, { target: { value: '12345' } });
    expect(screen.getByText('Create 0 test cases')).toBeInTheDocument();
    fireEvent.click(button);
    expect(screen.getByText('Create 1 test cases')).toBeInTheDocument();

    // coverage for reset button

    const resetButton = container.querySelector('#button-reset-form');
    fireEvent.click(resetButton);
    expect(screen.getByText('Create 0 test cases')).toBeInTheDocument();
  });

  it('should remove the row from preview table on click of trash icon', () => {
    const store = getStore();

    const { container } = render(
      <Provider store={store}>
        <CustomSeeds />
      </Provider>
    );

    const first_seed = seedTypes[0];
    const caseCountInput = screen.getByLabelText(`seed-count-${first_seed}`);
    const daysAgoInput = screen.getByLabelText(`days-ago-${first_seed}`);
    const cssIdInput = screen.getByLabelText(`css-id-${first_seed}`);
    const button = container.querySelector(`#btn-${first_seed}`);

    fireEvent.change(caseCountInput, { target: { value: '10' } });
    fireEvent.change(daysAgoInput, { target: { value: '5' } });
    fireEvent.change(cssIdInput, { target: { value: '12345' } });
    expect(screen.getByText('Create 0 test cases')).toBeInTheDocument();
    fireEvent.click(button);
    fireEvent.click(button);
    expect(screen.getByText('Create 2 test cases')).toBeInTheDocument();

    // coverage for trash button

    const trashButton = container.querySelector('#del-preview-row-0');
    fireEvent.click(trashButton);
    expect(screen.getByText('Create 1 test cases')).toBeInTheDocument();
  });

  it('should run reset all appeals query', () => {
    const store = getStore();

    const { container } = render(
      <Provider store={store}>
        <CustomSeeds />
      </Provider>
    );

    const button = container.querySelector('#button-Reset-all-appeals');

    ApiUtil.get.mockResolvedValueOnce({ data: 'Success' });
    fireEvent.click(button);

    expect(ApiUtil.get).toHaveBeenCalledWith(`/seeds/reset_all_appeals`);
  });
});
