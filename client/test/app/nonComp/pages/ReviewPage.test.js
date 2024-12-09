import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';

import ReduxBase from 'app/components/ReduxBase';
import ReviewPage from 'app/nonComp/pages/ReviewPage';
import CombinedNonCompReducer, { mapDataToInitialState } from 'app/nonComp/reducers';
import { vhaTaskFilterDetails } from 'test/data/taskFilterDetails';
import ApiUtil from 'app/util/ApiUtil';
import { MemoryRouter as Router } from 'react-router-dom';

const nonAdminVhaProps = {
  serverNonComp: {
    businessLine: 'Veterans Health Administration',
    businessLineUrl: 'vha',
    decisionIssuesStatus: {},
    isBusinessLineAdmin: false,
    businessLineConfig: {
      tabs: ['incomplete', 'in_progress', 'completed'],
      canGenerateClaimHistory: false,
    },
    taskFilterDetails: vhaTaskFilterDetails,
    featureToggles: {
      decisionReviewQueueSsnColumn: true
    }
  }
};

const adminVhaProps = {
  serverNonComp: {
    businessLine: 'Veterans Health Administration',
    businessLineUrl: 'vha',
    decisionIssuesStatus: {},
    isBusinessLineAdmin: true,
    businessLineConfig: {
      tabs: ['incomplete', 'in_progress', 'completed'],
      canGenerateClaimHistory: true,
    },
    taskFilterDetails: vhaTaskFilterDetails,
    featureToggles: {
      decisionReviewQueueSsnColumn: true
    }
  }
};

const renderReviewPage = (storeValues = {}) => {
  const initialState = mapDataToInitialState(storeValues);

  return render(
    <ReduxBase initialState={initialState} reducer={CombinedNonCompReducer} >
      <Router>
        <ReviewPage />
      </Router>
    </ReduxBase>
  );
};

beforeEach(() => {
  // Mock ApiUtil get so the tasks will appear in the queues.
  ApiUtil.get = jest.fn().mockResolvedValue({
    tasks: { data: [] },
    tasks_per_page: 15,
    task_page_count: 3,
    total_task_count: 44
  });
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('ReviewPage renders correctly for nonAdmin user', () => {
  it('passes a11y testing', async () => {
    const { container } = renderReviewPage(nonAdminVhaProps);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders correctly', () => {
    const { container } = renderReviewPage(nonAdminVhaProps);

    expect(container).toMatchSnapshot();
  });
});

describe('ReviewPage renders correctly for Admin user', () => {
  it('passes a11y testing', async () => {
    const { container } = renderReviewPage(adminVhaProps);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders correctly', () => {
    const { container } = renderReviewPage(adminVhaProps);

    expect(container).toMatchSnapshot();
  });
});

describe('ReviewPage with Non-admin Vha User', () => {
  beforeEach(() => {
    renderReviewPage(nonAdminVhaProps);
  });

  it('renders a button to intake a new form', () => {
    expect(screen.getByText('+ Intake new form')).toBeInTheDocument();
  });

  it('renders a button to download completed tasks', () => {
    expect(screen.getByText('Download completed tasks')).toBeInTheDocument();
  });

  it('does not render a button to generate task report', () => {
    expect(screen.queryByText('Generate task report')).not.toBeInTheDocument();
  });
});

describe('ReviewPage with Admin Vha User', () => {
  beforeEach(() => {
    renderReviewPage(adminVhaProps);
  });

  it('renders a button to intake a new form', () => {
    expect(screen.getByText('+ Intake new form')).toBeInTheDocument();
  });

  it('renders a button to download completed tasks', () => {
    expect(screen.getByText('Download completed tasks')).toBeInTheDocument();
  });

  it('does not render a button to generate task report', () => {
    expect(screen.getByText('Generate task report')).toBeInTheDocument();
  });
});
