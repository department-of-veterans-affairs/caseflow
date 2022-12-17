import React from 'react';
import { render } from '@testing-library/react';
import '@testing-library/jest-dom';
import NonCompTabsUnconnected from 'app/nonComp/components/NonCompTabs';
import { TaskTableUnconnected } from '../../../app/queue/components/TaskTable';

beforeEach(() => {
  jest.clearAllMocks();
});

const renderNonCompTabs = (props) => {
  return render(
    <NonCompTabsUnconnected {...props} />
  );
};

beforeEach(() => {
  renderNonCompTabs();
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('NonCompTabs', () => {
  it('renders a tab titled "In progress tasks"', () => {
    const props = {
      tabs: [{
        label: 'In progress tasks'
      },
      {
        label: 'Completed tasks'
      }]
    };

    renderNonCompTabs(props);

    expect(props.tabs[0]).toBe('In progress tasks');
  });

  it('renders a tab titled "Completed tasks"', () => {
    const props = {
      tabs: [{
        label: 'In progress tasks'
      },
      {
        label: 'Completed tasks'
      }]
    };

    renderNonCompTabs(props);

    expect(props.tabs[1]).toBe('In progress tasks');
  });

  it('renders TaskTableUnconnected Component', () => {
    const renderTaskTableUnconnected = (props) => {
      return render(
        <TaskTableUnconnected {...props} />
      );
    };

    expect(renderTaskTableUnconnected).toContain(
      this.state.taskPageApiEndpoint,
      this.state.useTaskPageApi,
      this.state.tabPaginationOptions);
  });
});
