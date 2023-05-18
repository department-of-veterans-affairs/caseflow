import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { CavcDashboardFooter } from '../../../../app/queue/cavcDashboard/CavcDashboardFooter';

const unmodifiedInitialState = {
  cavc_dashboards: [
    { cavc_docket_number: '12-3456', modified: false }
  ],
  checked_boxes: [
    { modified: false }
  ]
};

// changing a disposition modifies a nested attribute in cavc_dashboards
const modifiedDispositionInitialState = {
  cavc_dashboards: [
    { cavc_docket_number: '12-3456', modified: true }
  ],
  checked_boxes: [
    { modified: false }
  ]
};

// changing a decision reason modifies a nested attribute in checked_boxes
const modifiedReasonInitialState = {
  cavc_dashboards: [
    { cavc_docket_number: '12-3456', modified: false }
  ],
  checked_boxes: [
    { modified: true }
  ]
};

const cavcDashboards = [{ cavc_docket_number: '12-3456', modified: false }];

const checkedBoxes = [{ modified: false }];

const setProps = (modified, userCanEdit) => {
  let stateToProvide = null;

  switch (modified) {
  case 'disposition':
    stateToProvide = modifiedDispositionInitialState;
    break;
  case 'reason':
    stateToProvide = modifiedReasonInitialState;
    break;
  default:
    stateToProvide = unmodifiedInitialState;
    break;
  }

  return {
    userCanEdit,
    // history,
    // saveDashboardData,
    initialState: stateToProvide,
    cavcDashboards,
    checkedBoxes
  };
};

describe('cavcDashboardFooter', () => {
  it('Has no save button if user cannot edit', () => {
    render(<CavcDashboardFooter {...setProps(null, false)} />);

    expect(screen.queryByText('Save Changes')).toBeNull();
    expect(screen.getByText('Return to Case Details')).toBeEnabled();
  });

  it('Has save button disabled with no changes made', () => {
    render(<CavcDashboardFooter {...setProps(null, true)} />);

    expect(screen.getByText('Save Changes')).toBeDisabled();
  });

  it('Enables save button if changes were made to a disposition', () => {
    render(<CavcDashboardFooter {...setProps('disposition', true)} />);

    expect(screen.getByText('Save Changes')).toBeEnabled();
  });

  it('Enables save button if changes were made to a decision reason', () => {
    render(<CavcDashboardFooter {...setProps('reason', true)} />);

    expect(screen.getByText('Save Changes')).toBeEnabled();
  });

  it('Cancel brings up the cancel modal if changes were made', () => {
    render(<CavcDashboardFooter {...setProps('reason', true)} />);
    const cancelButton = screen.getByText('Cancel');

    fireEvent.click(cancelButton);
    expect(screen.queryByText('Your changes are not saved')).toBeTruthy();
    expect(screen.queryByText('CAVC appeals for')).toBeFalsy();
    expect(screen.queryByText('Currently active tasks')).toBeFalsy();
  });
});
