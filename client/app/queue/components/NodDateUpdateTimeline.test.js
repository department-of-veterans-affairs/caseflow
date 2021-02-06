import React from 'react';
import Enzyme, { shallow } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import { NodDateUpdateTimeline } from 'app/queue/components/NodDateUpdateTimeline';

Enzyme.configure({ adapter: new Adapter() });

describe('NodDateUpdateTimeline', () => {
  const nodDateUpdate = {
    changeReason: 'entry_error',
    newDate: '2021-01-12',
    oldDate: '2021-01-05',
    updatedAt: '2021-01-25T15:10:29.033-05:00',
    userFirstName: 'Jane',
    userLastName: 'Doe'
  };

  const setupNodDateUpdateTimeline = (timeline) => {
    return shallow(
      <NodDateUpdateTimeline
        nodDateUpdate={nodDateUpdate}
        timeline={timeline}
      />
    );
  };

  it('renders correctly', () => {
    const component = setupNodDateUpdateTimeline(true);

    expect(component).toMatchSnapshot();
  });

  it('should show update details', () => {
    const component = setupNodDateUpdateTimeline(true);

    expect(component.text()).toContain('01/05/2021');
    expect(component.text()).toContain('01/12/2021');
    expect(component.text()).toContain('J. Doe');
    expect(component.text()).toContain('Data Entry Error');
  });

  it('should not render if Task Rows is in Task Snapshot', () => {
    const component = setupNodDateUpdateTimeline(false);

    expect(component.find('tr').exists()).toEqual(false);
  });
});
