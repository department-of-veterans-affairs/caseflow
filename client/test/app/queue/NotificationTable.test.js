import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import ApiUtil from '../../../app/util/ApiUtil';
import NotificationTable from '../../../app/queue/components/NotificationTable';
import { notifications } from '../../data/notifications';

const createSpyGet = (data) => {
  return jest.spyOn(ApiUtil, 'get').
    mockImplementation(() => new Promise((resolve) => resolve({ body: data })));
};

const setup = () => {
  const props = {
    appealId: 'e1bdff31-4268-4fd4-a157-ebbd48013d91'
  };

  return render(
    <NotificationTable {...props} />
  );
};

beforeEach(() => {
  createSpyGet(notifications);
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('NotificationTable', () => {
  it('first event row should be the earliest notification sent', async () => {
    setup();
    const row = await screen.findAllByRole('cell');

    expect(row[0].textContent).toBe('Appeal decision mailed (Non-contested claims)');
  });

  it('first notification date row should be the earliest date', async () => {
    setup();
    const row = await screen.findAllByRole('cell');

    expect(row[1].textContent).toBe('10/27/2022');
  });

  it('last notification date row should be the latest date of the first page of records', async () => {
    setup();
    const row = await screen.findAllByRole('cell');

    expect(row[56].textContent).toBe('11/01/2022');
  });

  it('first notification type row should be email type', async () => {
    setup();
    const row = await screen.findAllByRole('cell');

    expect(row[2].textContent).toBe('Email');
  });

  it('second notification type row should be text type', async () => {
    setup();
    const row = await screen.findAllByRole('cell');

    expect(row[7].textContent).toBe('Text');
  });

  it('first recipient information row should be a dashed line', async () => {
    setup();
    const row = await screen.findAllByRole('cell');

    expect(row[3].textContent).toBe('—');
  });

  it('second recipient information row should be a phone number', async () => {
    setup();
    const row = await screen.findAllByRole('cell');

    expect(row[8].textContent).toBe('2468012345');
  });

  it('first status row should be not be delivered', async () => {
    setup();
    const row = await screen.findAllByRole('cell');

    expect(row[4].textContent).toBe('Sent');
  });

  it('second status row should be delivered', async () => {
    setup();
    const row = await screen.findAllByRole('cell');

    expect(row[9].textContent).toBe('Delivered');
  });

  it('matches snapshot', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('Virtual passes ally testing', async () => {
    const { container } = setup();
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
