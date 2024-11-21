import React from 'react';
import { axe } from 'jest-axe';
import { Provider } from 'react-redux';
import { MemoryRouter as Router } from 'react-router-dom';
import SaveSearchModal from 'app/nonComp/components/ReportPage/SaveSearchModal';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import createNonCompStore from 'test/app/nonComp/nonCompStoreCreator';

const userSearchParam = {
  savedSearch: {
    saveUserSearch: {
      radioEventAction: 'all_events_action',
      reportType: 'event_type_action',
      timing: {
        range: null
      }
    }
  }
};

const saveSearchStatus = {
  savedSearch: {
    saveUserSearch: {
      radioStatus: 'all_statuses',
      radioStatusReportType: 'last_action_taken',
      reportType: 'status',
      timing: {
        range: null
      }
    }
  }
};

const userSearchParamWithCondition = {
  savedSearch: {
    saveUserSearch: {
      radioStatus: 'all_statuses',
      radioStatusReportType: 'last_action_taken',
      reportType: 'status',
      timing: {
        range: null
      },
      conditions: [
        {
          options: {
            comparisonOperator: 'lessThan',
            valueOne: 5
          },
          condition: 'daysWaiting'
        },
        {
          condition: 'issueType',
          options: {
            issueTypes: [
              {
                value: 'Camp Lejune Family Member',
                label: 'Camp Lejune Family Member'
              },
              {
                value: 'Caregiver | Eligibility',
                label: 'Caregiver | Eligibility'
              }
            ]
          }
        },
        {
          condition: 'issueDisposition',
          options: {
            issueDispositions: [
              {
                label: 'Blank',
                value: 'blank'
              },
              {
                label: 'Denied',
                value: 'denied'
              },
              {
                label: 'Dismissed',
                value: 'dismissed'
              }
            ]
          }
        },
        {
          condition: 'decisionReviewType',
          options: {
            decisionReviewTypes: [
              {
                label: 'Higher-Level Reviews',
                value: 'HigherLevelReview'
              },
              {
                label: 'Supplemental Claims',
                value: 'SupplementalClaim'
              }
            ]
          }
        },
        {
          condition: 'personnel',
          options: {
            personnel: [
              {
                label: 'Karmen Deckow DDS',
                value: 'PTBRADFAVBAS'
              },
              {
                label: 'Gerard Parisian LLD',
                value: 'THOMAW2VACO'
              }
            ]
          }
        }
      ]
    }
  }
};

describe('SaveSearchModal', () => {
  const setup = (storeValues = {}) => {
    const store = createNonCompStore(storeValues);

    return render(
      <Provider store={store}>
        <Router>
          <SaveSearchModal />
        </Router>
      </Provider>
    );
  };

  describe('renders correctly', () => {
    it('passes a11y testing', async () => {
      const { container } = setup(userSearchParam);

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('renders correctly', () => {
      const { container } = setup(userSearchParam);

      expect(container).toMatchSnapshot();
    });
  });

  describe('Save search button', () => {
    it('should have Save search button disabled', () => {
      setup(userSearchParam);
      const saveSearchButton = screen.getByText('Save search');

      expect(saveSearchButton).toBeDisabled();
    });

    it('should enable Save search button after required field is filled', () => {
      setup(userSearchParam);
      const saveSearchButton = screen.getByText('Save search');

      expect(saveSearchButton).toBeDisabled();

      const searchName = screen.getByRole('textbox', { name: 'Name this search (Max 50 characters)' });

      userEvent.type(searchName, 'My first search');
      expect(searchName).toHaveValue('My first search');

      expect(saveSearchButton).not.toBeDisabled();
    });

    it('should not enable the Save Search button if only optional fields are filled', () => {
      setup(userSearchParam);
      const saveSearchButton = screen.getByText('Save search');

      screen.getByText('Description of search (Max 100 characters)');

      expect(saveSearchButton).toBeDisabled();
    });
  });

  describe('Search parameter', () => {
    describe('Report Type', () => {
      it('render Event Type title and Event type params', () => {
        setup(userSearchParam);

        expect(screen.getAllByText('Event / Action:').length).toBe(1);
        expect(screen.getAllByText('All Events / Actions').length).toBe(1);
      });

      it('renders specific selected event types', () => {
        const newUserParam = { ...userSearchParam };

        newUserParam.savedSearch.saveUserSearch.radioEventAction = 'specific_events_action';
        newUserParam.savedSearch.saveUserSearch.specificEventType = {
          claim_created: true,
          claim_closed: true,
          added_issue_no_decision_date: true,
          removed_issue: true
        };

        setup(newUserParam);
        const listOfSelected = ['Claim created', 'Claim closed', 'Added issue - No decision date', 'Removed issue'];
        const expectationString = `Specific Events / Actions - ${listOfSelected.join(', ')}`;

        expect(screen.getAllByText('Event / Action:').length).toBe(1);
        expect(screen.getAllByText(expectationString).length).toBe(1);
      });

      it('render report Type status and All status as selected option', () => {
        setup(saveSearchStatus);

        expect(screen.getAllByText('Status:').length).toBe(1);
        expect(screen.getAllByText('All Statuses').length).toBe(1);
        expect(screen.getAllByText('Type of Status Report:').length).toBe(1);
        expect(screen.getAllByText('Last Action Taken').length).toBe(1);
      });

      it('render report Type status and selected specific status', () => {
        const newParams = { ...saveSearchStatus };

        newParams.savedSearch.saveUserSearch.radioStatus = 'specific_status';
        newParams.savedSearch.saveUserSearch.specificStatus = {
          incomplete: true,
          pending: true,
          completed: true,
          cancelled: true
        };
        newParams.savedSearch.saveUserSearch.radioStatusReportType = 'summary';
        const listOfSelected = ['Incomplete', 'Pending', 'Completed', 'Cancelled'];
        const expectationString = `Specific Status - ${listOfSelected.join(', ')}`;

        setup(newParams);
        expect(screen.getAllByText('Status:').length).toBe(1);
        expect(screen.getAllByText('Type of Status Report:').length).toBe(1);
        expect(screen.getAllByText('Summary').length).toBe(1);
        expect(screen.getAllByText(expectationString).length).toBe(1);
      });
    });

    describe('timing specification', () => {
      it('renders timing specification with After value and specified date', () => {
        const newUserParam = { ...userSearchParam };

        newUserParam.savedSearch.saveUserSearch.timing = { range: 'after', startDate: '2024-11-04T07:00:00.000Z' };

        setup(newUserParam);
        expect(screen.getAllByText('Timing Specifications:').length).toBe(1);
        expect(screen.getAllByText('After 11/04/2024').length).toBe(1);
      });

      it('renders timing specification with before value and specified date', () => {
        const newUserParam = { ...userSearchParam };

        newUserParam.savedSearch.saveUserSearch.timing = { range: 'before', startDate: '2024-11-04T07:00:00.000Z' };

        setup(newUserParam);

        expect(screen.getAllByText('Before 11/04/2024').length).toBe(1);
      });

      it('renders timing specification with between values and specified date', () => {
        const newUserParam = { ...userSearchParam };

        newUserParam.savedSearch.saveUserSearch.timing =
          { range: 'between', startDate: '2024-11-04T07:00:00.000Z', endDate: '2024-11-05T07:00:00.000Z' };

        setup(newUserParam);

        expect(screen.getAllByText('Between 11/04/2024 to 11/05/2024').length).toBe(1);
      });

      it('renders timing specification with Last 7 days', () => {
        const newUserParam = { ...userSearchParam };

        newUserParam.savedSearch.saveUserSearch.timing = { range: 'last_7_days' };

        setup(newUserParam);

        expect(screen.getAllByText('Last 7 Days').length).toBe(1);
      });

      it('renders timing specification with Last 30 days', () => {
        const newUserParam = { ...userSearchParam };

        newUserParam.savedSearch.saveUserSearch.timing = { range: 'last_30_days' };

        setup(newUserParam);

        expect(screen.getAllByText('Last 30 Days').length).toBe(1);
      });

      it('renders timing specification with Last 365 days', () => {
        const newUserParam = { ...userSearchParam };

        newUserParam.savedSearch.saveUserSearch.timing = { range: 'last_365_days' };

        setup(newUserParam);

        expect(screen.getAllByText('Last 365 Days').length).toBe(1);
      });
    });

    describe('Condition', () => {
      it('should render all selected conditions', () => {
        setup(userSearchParamWithCondition);

        expect(screen.getAllByText('Conditions Days Waiting:').length).toBe(1);
        expect(screen.getAllByText('Less than 5 days').length).toBe(1);
        expect(screen.getAllByText('Conditions Issue Type:').length).toBe(1);
        expect(screen.getAllByText('Camp Lejune Family Member, Caregiver | Eligibility').length).toBe(1);

        expect(screen.getAllByText('Conditions Issue Disposition:').length).toBe(1);
        expect(screen.getAllByText('Blank, Denied, Dismissed').length).toBe(1);
        expect(screen.getAllByText('Conditions Decision Review Type:').length).toBe(1);
        expect(screen.getAllByText('Higher-Level Reviews, Supplemental Claims').length).toBe(1);

        expect(screen.getAllByText('Conditions Personnel:').length).toBe(1);
        expect(screen.getAllByText('Karmen Deckow DDS, Gerard Parisian LLD').length).toBe(1);
      });
    });
  });
});
