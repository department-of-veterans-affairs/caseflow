import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import ApiUtil from '../../../../../app/util/ApiUtil';
import PackageFilesModal from '../../../../../app/hearings/components/transcriptionProcessing/PackageFilesModal';
import { transcriptionContractors } from '../../../../data/transcriptionContractors';
import { axe } from 'jest-axe';
import { BrowserRouter as Router } from 'react-router-dom';

const getSpy = jest.spyOn(ApiUtil, 'get');

const setup = () => {
  const onCancel = jest.fn();

  const returnDates = ['09/05/2024', '08/25/2024'];

  return render(
    <Router>
      <PackageFilesModal onCancel={onCancel} contractors={transcriptionContractors} returnDates={returnDates} />
    </Router>
  );
};

const mockTaskId = (taskId) => {
  getSpy.mockImplementationOnce(() => new Promise((resolve) => resolve({ body: { task_id: taskId } })));
};

describe('Package files modal', () => {
  it('radio button displays correct dates', () => {
    mockTaskId(347);
    setup();

    expect(screen.getByRole('radio', { name: 'Return in 15 days (09/05/2024)' })).toBeInTheDocument();
    expect(screen.getByRole('radio', { name: 'Expedite (Maximum of 5 days)', value: { text: '08/25/2024' } })).
      toBeInTheDocument();
  });

  it('dropdown displays contractors', () => {
    mockTaskId(347);
    setup();
    const dropdown = screen.getByRole('combobox');

    fireEvent.change(dropdown, { target: { value: 3 } });

    expect(screen.getByText('The Ravens Group, Inc.')).toBeInTheDocument();
  });

  it('generates work order properly when task id is low', async () => {
    mockTaskId(347);
    const year = new Date().getFullYear();

    setup();

    expect(await screen.findByText(`BVA-${year}-0347`)).toBeInTheDocument();
  });

  it('generates work order properly when task id is high', async () => {
    mockTaskId(346749);
    const year = new Date().getFullYear().
      toString().
      substring(2);

    setup();

    expect(await screen.findByText(`BVA-${year}34-6749`)).toBeInTheDocument();
  });

  it('matches snapshot', async () => {
    mockTaskId(347);
    const year = new Date().getFullYear();

    const { container} = setup();

    expect(await screen.findByText(`BVA-${year}-0347`)).toBeInTheDocument();
    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    jest.useRealTimers();
    mockTaskId(346749);
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
