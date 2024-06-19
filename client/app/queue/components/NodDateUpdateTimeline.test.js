import React from 'react';
import * as redux from 'react-redux';
import { render, screen } from '@testing-library/react';
import { NodDateUpdateTimeline } from 'app/queue/components/NodDateUpdateTimeline';

describe('NodDateUpdateTimeline', () => {
  const nodDateUpdate = {
    changeReason: 'entry_error',
    newDate: '2021-01-12',
    oldDate: '2021-01-05',
    updatedAt: '2021-01-25T15:10:29.033-05:00',
    userFirstName: 'Jane',
    userLastName: 'Doe'
  };

  beforeEach(() => {
    const spy = jest.spyOn(redux, 'useSelector');

    spy.mockReturnValue({ nod_date_updates: true });
  });

  const setupNodDateUpdateTimeline = (timeline) => {
    return render(
      <NodDateUpdateTimeline
        timelineEvent={nodDateUpdate}
        timeline={timeline}
      />
    );
  };

  it('renders correctly', () => {
    const { asFragment } = setupNodDateUpdateTimeline(true);

    expect(asFragment()).toMatchSnapshot();
  });

  it('should show update details', () => {
    setupNodDateUpdateTimeline(true);

    expect(screen.getByText('01/05/2021')).toBeInTheDocument();
    expect(screen.getByText('01/12/2021')).toBeInTheDocument();
    expect(screen.getByText('J. Doe')).toBeInTheDocument();
    expect(screen.getByText('Data Entry Error')).toBeInTheDocument();
  });

  it('should not render if Task Rows is in Task Snapshot', () => {
    setupNodDateUpdateTimeline(false);

    expect(screen.queryAllByRole('row')).toHaveLength(0);
  });
});
