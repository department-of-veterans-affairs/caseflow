import React from 'react';
import { Button } from 'app/hearings/components/dailyDocket/DailyDocketRow';
import { shallow } from 'enzyme';

describe('Test Button component', () => {

  it('Test click event without throwing an error', () => {
    const { conferenceLink } = this.props;

    window.open(conferenceLink?.hostLink);
    const conferenceLinkOnClick = jest.fn();

    const button = shallow((<Button
      classNames={['usa-button-secondary']}
      type="button"
      onClick={this.conferenceLinkOnClick} > Connect to Recording System</Button>));

    button.find('button').simulate('click');
    expect(conferenceLinkOnClick.mock.calls.length).toEqual(1);
  }
  );
});
