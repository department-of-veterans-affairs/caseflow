import React from 'react';
import { Button } from 'app/hearings/components/dailyDocket/DailyDocketRow';
import { shallow } from 'enzyme';

describe('Test Button component', () => {
  it('Test click event', () => {
    const { conferenceLink } = this.props;

    window.open(conferenceLink?.hostLink);
    const conferenceLinkOnClick = jest.fn();

    const button = shallow((<Button
      classNames={['usa-button-secondary']}
      type="button"
      onClick={this.conferenceLinkOnClick} > Connect to Recording System</Button>));

    button.find('button').simulate('click');
    expect(conferenceLinkOnClick.mock.calls.length).toEqual(1);
  });
});
/*Test Button component › Test click event

TypeError: Cannot read property 'conferenceLinkOnClick' of undefined

14 |       classNames={['usa-button-secondary']}
15 |       type="button"
> 16 |       onClick={this.conferenceLinkOnClick} > Connect to Recording System</Button>));
   |                     ^
17 |
18 |     button.find('button').simulate('click');
19 |     expect(conferenceLinkOnClick.mock.calls.length).toEqual(1);*/