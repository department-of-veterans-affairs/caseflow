import React from 'react';
import { amaHearing } from 'test/data/hearings';
import { anyUser, vsoUser } from 'test/data/user';
import { Button } from 'app/hearings/components/dailyDocket/DailyDocketRow';
import { axe } from 'jest-axe';
import { render, screen, fireEvent } from '@testing-library/react';
import { shallow } from 'enzyme';

describe('Test Button component', () => {
  it('Test click event', () => {
    const conferenceLinkOnClick = jest.fn();

    const button = shallow((<Button onClick={conferenceLinkOnClick}>Ok!</Button>));

    button.find('button').simulate('click');
    expect(conferenceLinkOnClick.mock.calls.length).toEqual(1);
  });
});
