import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';

import ReduxBase from 'app/components/ReduxBase';
import ClaimHistoryPage from 'app/nonComp/pages/ClaimHistoryPage';
import CombinedNonCompReducer, { mapDataToInitialState } from 'app/nonComp/reducers';

const adminVhaProps = {
  serverNonComp: {
    task: {
      claimant: {
        name: 'Bob Smithgreen',
        relationship: 'self'
      },
      appeal: {
        id: '17',
        isLegacyAppeal: false,
        issueCount: 1,
        activeOrDecidedRequestIssues: [
          {
            id: 3710,
            rating_issue_reference_id: null,
            rating_issue_profile_date: null,
            rating_decision_reference_id: null,
            description: 'Beneficiary Travel - sdad',
            contention_text: 'Beneficiary Travel - sdad',
            approx_decision_date: '2023-03-30',
            category: 'Beneficiary Travel',
            notes: null,
            is_unidentified: null,
            ramp_claim_id: null,
            vacols_id: null,
            vacols_sequence_id: null,
            ineligible_reason: null,
            ineligible_due_to_id: null,
            decision_review_title: 'Higher-Level Review',
            title_of_active_review: null,
            contested_decision_issue_id: null,
            withdrawal_date: null,
            contested_issue_description: null,
            end_product_code: null,
            end_product_establishment_code: null,
            verified_unidentified_issue: null,
            editable: true,
            exam_requested: null,
            vacols_issue: null,
            end_product_cleared: null,
            benefit_type: 'vha',
            is_predocket_needed: null
          }
        ],
        appellant_type: null
      },
      power_of_attorney: {
        representative_type: 'Attorney',
        representative_name: 'Clarence Darrow',
        representative_address: {
          address_line_1: '9999 MISSION ST',
          address_line_2: 'UBER',
          address_line_3: 'APT 2',
          city: 'SAN FRANCISCO',
          zip: '94103',
          country: 'USA',
          state: 'CA'
        },
        representative_email_address: 'jamie.fakerton@caseflowdemo.com'
      },
      appellant_type: null,
      issue_count: 1,
      tasks_url: '/decision_reviews/vha',
      id: 10467,
      created_at: '2023-05-01T12:54:22.123-04:00',
      veteran_participant_id: '253956744',
      veteran_ssn: '800124578',
      assigned_on: '2023-05-01T12:54:22.123-04:00',
      assigned_at: '2023-05-01T12:54:22.123-04:00',
      closed_at: '2023-05-01T13:25:21.367-04:00',
      started_at: null,
      type: 'Higher-Level Review',
      business_line: 'vha'
    },
  }
};

const renderClaimHistoryPage = (storeValues = {}) => {
  const initialState = mapDataToInitialState(storeValues);

  return render(
    <ReduxBase initialState={initialState} reducer={CombinedNonCompReducer} >
      <ClaimHistoryPage />
    </ReduxBase>
  );
};

describe('ClaimHistoryPage renders correctly for Admin user', () => {
  it('passes a11y testing', async () => {
    const { container } = renderClaimHistoryPage(adminVhaProps);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders correctly', () => {
    const { container } = renderClaimHistoryPage(adminVhaProps);

    expect(container).toMatchSnapshot();
  });

  it('displays the claimant\'s name', () => {
    renderClaimHistoryPage(adminVhaProps);

    expect(screen.getByText(adminVhaProps.serverNonComp.task.claimant.name)).toBeInTheDocument();
  });

  it('displays the back link', () => {
    renderClaimHistoryPage(adminVhaProps);

    expect(screen.getByText('< Back to Decision Review')).toBeInTheDocument();
  });
});
