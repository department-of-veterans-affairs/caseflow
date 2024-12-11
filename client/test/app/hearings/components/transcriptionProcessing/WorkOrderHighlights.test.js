import React from 'react';
import { render, screen } from '@testing-library/react';
import WorkOrderHightlightsModal from
  '../../../../../app/hearings/components/transcriptionProcessing/WorkOrderHighlightsModal';
import ApiUtil from '../../../../../app/util/ApiUtil';
import { axe } from 'jest-axe';

const onCancel = jest.fn();
const getSpy = jest.spyOn(ApiUtil, 'get');
const workOrder = 'BVA20240012';
const mockedContent = {
  data: [
    {
      docketNumber: '123-4567',
      caseDetails: 'Joe Shmoe (111111111)',
      hearingType: 'Hearing',
      appealId: '9cddd24a-866a-4b88-ac2c-b79cb63d5e02'
    },
    {
      docketNumber: '987-6543',
      caseDetails: 'Jane Shmoe (111111111)',
      hearingType: 'LegacyHearing',
      appealId: '9739'
    }
  ]
};

const expectedCellContent = [
  '1.', 'H', 'Joe Shmoe (111111111)',
  '2.', 'L', 'Jane Shmoe (111111111)'
];

const expectedLinks = [
  '/queue/appeals/9cddd24a-866a-4b88-ac2c-b79cb63d5e02',
  '/queue/appeals/9739'
];

beforeEach(() => {
  getSpy.mockImplementation(() => new Promise((resolve) => resolve({ body: mockedContent })));
});

const setup = () => {
  return render(<WorkOrderHightlightsModal onCancel={onCancel} workOrder={workOrder} />);
};

describe('WorkOrderHighlights', () => {
  it('renders the work order in the title properly', () => {
    setup();
    expect(screen.getByText('Order contents of work order #BVA-2024-0012')).toBeInTheDocument();
  });

  it('renders the correct table values', async () => {
    setup();
    const cells = await screen.findAllByRole('cell');
    const cellContent = cells.map((cell, index) => {
      if (index === 1 || index === 4) {
        return cell.textContent.charAt(0);
      }

      return cell.textContent;
    });

    expect(cellContent).toStrictEqual(expectedCellContent);
  });

  it('case details link to the correct pages', async () => {
    setup();
    const cells = await screen.findAllByRole('link');
    const links = [cells[0].getAttribute('href'), cells[1].getAttribute('href')];

    expect(links).toStrictEqual(expectedLinks);

  });

  it('matches snapshot', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
