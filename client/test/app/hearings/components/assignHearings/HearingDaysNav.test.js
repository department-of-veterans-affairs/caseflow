import React from 'react';
import lodash from 'lodash';

import { HearingDaysNav } from 'app/hearings/components/assignHearings/HearingDaysNav';
import { render, fireEvent, screen, wait } from '@testing-library/react';
import { generateHearingDays } from 'test/data/hearings';
import * as utils from 'app/hearings/utils';

const defaultNumberHearingDays = 5;

describe('HearingDaysNav', () => {
  test('Matches snapshot with default props', () => {
    // Setup the test
    const hearingDays = generateHearingDays('RO17', defaultNumberHearingDays);

    // Run the test
    const nav = render(
      <HearingDaysNav
        upcomingHearingDays={hearingDays}
        selectedHearingDay={hearingDays[0]}
      />
    );

    // Expect to find the July 2020 header (see: client/test/app/jestSetup.js)
    expect(nav.container.querySelector('label')).toHaveTextContent('July 2020');
    expect(nav.container.getElementsByTagName('label')).toHaveLength(1);
    expect(nav.container.getElementsByClassName('selected-hearing-day-info-button')).toHaveLength(1);
    expect(nav.container.querySelector('.selected-hearing-day-info-button')).toHaveTextContent('Mon Jul 6');
    expect(nav.container.getElementsByClassName('cf-btn-link usa-button')).toHaveLength(defaultNumberHearingDays);

    expect(nav).toMatchSnapshot();
  });

  test('Runs scroll event callback when scrolling in the list container', () => {
    // Setup the test
    const analyticsSpy = jest.spyOn(window, 'analyticsEvent');
    const debounceSpy = jest.spyOn(lodash, 'debounce');
    const hearingDays = generateHearingDays('RO17', 31);

    // Run the test
    const nav = render(<HearingDaysNav upcomingHearingDays={hearingDays} selectedHearingDay={hearingDays[0]} />);

    // Test the initial state
    expect(nav.container.getElementsByTagName('label')).toHaveLength(2);
    expect(nav.container.getElementsByTagName('label')[0]).toHaveTextContent('July 2020');
    expect(nav.container.getElementsByTagName('label')[1]).toHaveTextContent('August 2020');

    // Fire the scroll event
    fireEvent.scroll(nav.container.querySelector('.hearing-day-list'), { target: { scrollY: 100 } });

    // Assert the analytics event was called
    wait(() => {
      expect(analyticsSpy).toHaveBeenCalledWith('Hearings', 'Available Hearing Days – Scroll ');
    }, 250);

    // Test the debounce was called with an anonymous function
    expect(debounceSpy).toHaveBeenCalledWith(expect.any(Function), 250);

    expect(nav).toMatchSnapshot();
  });

  test('Runs the change hearing day event callback on click', () => {
    // Setup the test
    const selectEvent = jest.spyOn(utils, 'selectHearingDayEvent');
    const hearingDays = generateHearingDays('RO17', defaultNumberHearingDays);
    const changeDaySpy = jest.fn();
    const analyticsSpy = jest.spyOn(window, 'analyticsEvent');

    // Run the test
    const nav = render(
      <HearingDaysNav
        upcomingHearingDays={hearingDays}
        selectedHearingDay={hearingDays[0]}
        onSelectedHearingDayChange={changeDaySpy}
      />
    );

    // Change the selection to the second button
    fireEvent.click(screen.getAllByRole('button')[1]);

    // Test that the callback was fired with the correct date
    expect(changeDaySpy).toHaveBeenCalledWith(hearingDays[1]);
    expect(selectEvent).toHaveBeenCalledWith(changeDaySpy);
    expect(analyticsSpy).toHaveBeenCalledWith(
      'Hearings',
      'Available Hearing Days – Select',
      '',
      '1 days between selected hearing day and today'
    );

    expect(nav).toMatchSnapshot();
  });

  test('Applies the selected class based on the selectedHearingDay prop', () => {
    // Setup the test
    const hearingDays = generateHearingDays('RO17', defaultNumberHearingDays);

    // Run the test
    const nav1 = render(<HearingDaysNav upcomingHearingDays={hearingDays} selectedHearingDay={hearingDays[0]} />);
    const nav2 = render(<HearingDaysNav upcomingHearingDays={hearingDays} selectedHearingDay={hearingDays[1]} />);

    // Test there is only 1 selected hearing day and it is the one passed as the prop
    expect(nav1.container.getElementsByClassName('selected-hearing-day-info-button')).toHaveLength(1);
    expect(nav1.container.querySelector('.selected-hearing-day-info-button')).toHaveTextContent('Mon Jul 6');

    expect(nav2.container.getElementsByClassName('selected-hearing-day-info-button')).toHaveLength(1);
    expect(nav2.container.querySelector('.selected-hearing-day-info-button')).toHaveTextContent('Tue Jul 7');

    expect(nav1).toMatchSnapshot();
    expect(nav2).toMatchSnapshot();
  });

});
