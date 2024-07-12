import React from 'react';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import mockProps from 'app/intake/components/RemoveIssueModal/mockProps';
import RemoveIssueModal from 'app/intake/components/RemoveIssueModal/RemoveIssueModal';
import rootReducer from 'app/queue/reducers';

jest.mock('redux', () => ({
  ...jest.requireActual('redux'),
  bindActionCreators: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));

describe('RemoveIssueModal', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  const mockOnClickIssueAction = jest.fn();

  const store = createStore(rootReducer, applyMiddleware(thunk));

  const setup = (testProps) =>
    render(
      <Provider store={store}>
        <RemoveIssueModal
          {...testProps}
          removeIssue={mockOnClickIssueAction}
        />
      </Provider>
    );

  it('renders', () => {
    const modal = setup(mockProps);

    expect(modal).toMatchSnapshot();
    expect(screen.getByText('Remove issue')).toBeInTheDocument();
  });

  it('calls the removeIssue function when button is clicked', () => {
    setup(mockProps);
    screen.getByText('Remove').click();

    expect(mockOnClickIssueAction).toHaveBeenCalled();
  });

  describe('different issue messages for different issues', () => {
    it('displays non VBMS benefit type message', () => {
      setup(mockProps);

      expect(screen.getByText(
        'The contention you selected will be removed from the decision review.'
      )).toBeInTheDocument();
      expect(screen.getByText(
        'Are you sure you want to remove this issue?'
      )).toBeInTheDocument();
    });

    it('displays appeal formType message', () => {
      setup({ ...mockProps, intakeData: { benefitType: 'compensation', formType: 'appeal' } });

      expect(screen.getByText(
        'The issue you selected will be removed from the list of issues on appeal.'
      )).toBeInTheDocument();
      expect(screen.getByText(
        "Are you sure that this issue is not listed on the veteran's NOD and that you want to remove it?"
      )).toBeInTheDocument();
    });

    it('displays default message', () => {
      setup({ ...mockProps, intakeData: { benefitType: 'pension', formType: 'higher_level_review' } });

      expect(screen.getByText(
        'The contention you selected will be removed from the EP in VBMS.'
      )).toBeInTheDocument();
      expect(screen.getByText(
        'Are you sure you want to remove this issue?'
      )).toBeInTheDocument();
    });
  });
});
