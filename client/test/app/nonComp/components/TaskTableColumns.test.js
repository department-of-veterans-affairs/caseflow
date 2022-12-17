import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { claimantColumn } from 'app/queue/components/TaskTableColumns';

beforeEach(() => {
  jest.clearAllMocks();
});

const renderClaimantColumn = () => {
  return render(
    claimantColumn
  );
};

beforeEach(() => {
  renderClaimantColumn();
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('claimantColumn', () => {
  it('contains valueFunction prop', () => {
    const valueFunctionProp = (task) => {
      return <a href={`/decision_reviews/${task.businessLine}/tasks/${task.id}`}>{task.claimant.name}</a>;
    };

    valueFunctionProp();

    expect(screen.getAllByText).toContain(/task.businessLine/);
  }
  );
});
