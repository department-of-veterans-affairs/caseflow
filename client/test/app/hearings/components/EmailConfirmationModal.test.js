import React from 'react';
import { render, screen } from '@testing-library/react';

import EmailConfirmationModal, {
  ChangeHearingTime,
  ChangeToVirtual,
  ChangeFromVirtual,
  ChangeEmailOrTimezone
  , DateTime, ReadOnlyEmails } from 'app/hearings/components/EmailConfirmationModal';
import { defaultHearing, virtualHearing } from 'test/data';
import { HEARING_CONVERSION_TYPES } from 'app/hearings/constants';
import moment from 'moment-timezone';

import { zoneName } from 'app/hearings/utils';
import { centralHearing } from 'test/data/hearings';
import COPY from 'COPY';

// Setup the test constants
const updateSpy = jest.fn();
const error = 'Something went wrong...';
const location = { name: 'Somewhere' };
const hearingDayDate = '2025-01-01';

const expectAllEmailsAssertion = (screen, container, hearing) => {
  expect(screen.getAllByTestId('read-only-testid')).toHaveLength(4);
  expect(screen.getAllByText(convertRegexScheduleTime(zoneName(hearing.scheduledTimeString, hearing.appellantTz))).length).toBeGreaterThan(0);
  expect(screen.getAllByText(convertRegex(hearing.appellantEmailAddress)).length).toBeGreaterThan(0);
  expect(screen.getAllByText(convertRegex(hearing.representativeEmailAddress)).length).toBeGreaterThan(0);
  expect(container.querySelector('.cf-help-divider')).toBeInTheDocument();
};

const expectSingleEmailAssertion = (screen, container, hearing) => {
  expect(screen.getAllByTestId('read-only-testid')).toHaveLength(2);
  expect(screen.getByText(convertRegexScheduleTime(zoneName(hearing.scheduledTimeString, hearing.appellantTz)))).toBeInTheDocument();
  expect(screen.getByText(convertRegex(hearing.appellantEmailAddress))).toBeInTheDocument();
  expect(container.querySelector('.cf-help-divider')).not.toBeInTheDocument();
};

const expectHearingDateAndTime = (screen) => {
  const date = moment(defaultHearing.scheduledFor).format('MM/DD/YYYY');
  const scheduleTime = zoneName(defaultHearing.scheduledTimeString)
  expect(screen.getByText('Hearing Date:')).toBeInTheDocument();
  expect(screen.getByText(convertRegex(date))).toBeInTheDocument();
  expect(screen.getByText('Hearing Time:')).toBeInTheDocument();
  expect(screen.getByText(convertRegexScheduleTime(scheduleTime))).toBeInTheDocument();
};

const convertRegex = (str) => {
  return new RegExp(str, 'i');
}

function convertRegexScheduleTime(str) {
  const escapedStr = str.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
  return new RegExp(escapedStr);
}

describe('EmailConfirmationModal', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const { asFragment } = render(
      <EmailConfirmationModal
        update={updateSpy}
        hearing={defaultHearing}
        virtualHearing={virtualHearing.virtualHearing}
        type={HEARING_CONVERSION_TYPES[0]}
      />);


    // Assertions
    expect(screen.getByRole('heading', { name: 'Change to Virtual Hearing' })).toBeInTheDocument();
    expect(screen.getByText(convertRegex(defaultHearing.scheduledTimeString))).toBeInTheDocument();

    const veteranEmail = screen.getByRole('textbox', { name: 'Veteran Email' });
    expect(veteranEmail.value).toEqual(virtualHearing.virtualHearing.appellantEmail);

    const representativeEmail = screen.getByRole('textbox', { name: 'POA/Representative Email' });
    expect(representativeEmail.value).toEqual(virtualHearing.virtualHearing.representativeEmail);

    expect(screen.getByRole('button', { name: 'Change and Send Email' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays ChangeFromVirtual component when type is change_from_virtual', () => {
    // Run the test
    const { asFragment } = render(
      <EmailConfirmationModal
        update={updateSpy}
        hearing={defaultHearing}
        virtualHearing={virtualHearing.virtualHearing}
        type={HEARING_CONVERSION_TYPES[1]}
      />);

    // Assertions
    expect(screen.getAllByText(convertRegex(defaultHearing.appellantEmailAddress)).length).toBeGreaterThan(0);
    expect(screen.getByRole('heading', { name: 'Change to Video Hearing' })).toBeInTheDocument();
    expect(screen.getByText(convertRegex(defaultHearing.scheduledTimeString))).toBeInTheDocument();
    expect(screen.getAllByText(convertRegex(defaultHearing.appellantEmailAddress)).length).toBeGreaterThan(0);
    expect(screen.getAllByText(convertRegex(defaultHearing.representativeEmailAddress)).length).toBeGreaterThan(0);
    expect(screen.getByRole('button', { name: 'Change and Send Email' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays ChangeEmailOrTimezone component when type is change_email_or_timezone', () => {
    // Run the test
    const { asFragment } = render(
      <EmailConfirmationModal
        update={updateSpy}
        hearing={defaultHearing}
        virtualHearing={virtualHearing.virtualHearing}
        type={HEARING_CONVERSION_TYPES[2]}
      />);

    // Assertions
    expect(screen.getByRole('heading', { name: 'Update Timezone' })).toBeInTheDocument();
    expect(screen.getByText(COPY.VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_INTRO)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Update and Send Email' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays ChangeHearingTime component when type is change_hearing_time', () => {
    // Run the test
    const { asFragment } = render(
      <EmailConfirmationModal
        update={updateSpy}
        hearing={defaultHearing}
        virtualHearing={virtualHearing.virtualHearing}
        type={HEARING_CONVERSION_TYPES[3]}
      />);

    // Assertions
    expect(screen.getByRole('heading', { name: 'Update Hearing Time' })).toBeInTheDocument();
    expect(screen.getByText(convertRegex(defaultHearing.scheduledTimeString))).toBeInTheDocument();
    expect(screen.getAllByText(convertRegex(defaultHearing.appellantEmailAddress)).length).toBeGreaterThan(0);
    expect(screen.getAllByText(convertRegex(defaultHearing.representativeEmailAddress)).length).toBeGreaterThan(0);
    expect(screen.getByRole('button', { name: 'Update Hearing Time' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  describe('ChangeToVirtual sub-component', () => {
    test('Displays input for appellant and representative email', () => {
      // Run the test
      const { asFragment } = render(
        <ChangeToVirtual
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />);

      // Assertions
      expectHearingDateAndTime(screen);
      expect(screen.getByRole('textbox', { name: 'Veteran Email' }).value).toEqual(virtualHearing.virtualHearing.appellantEmail);
      expect(screen.getByRole('textbox', { name: 'POA/Representative Email' }).value).toEqual(virtualHearing.virtualHearing.representativeEmail);
      expect(asFragment()).toMatchSnapshot();
    });

    test('Displays appellant email error when present', () => {
      // Run the test
      const { container, asFragment } = render(
        <ChangeToVirtual
          appellantEmailError={error}
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />);

      // Assertions
      expect(container.querySelector('.usa-input-error-message')).toBeInTheDocument();
      expect(screen.getByText(error)).toBeInTheDocument();
      expect(asFragment()).toMatchSnapshot();
    });

    test('Displays representative email error when present', () => {
      // Run the test
      const { container, asFragment } = render(
        <ChangeToVirtual
          representativeEmailError={error}
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />);

      // Assertions
      expect(container.querySelector('.usa-input-error-message')).toBeInTheDocument();
      expect(screen.getByText(error)).toBeInTheDocument();
      expect(asFragment()).toMatchSnapshot();
    });
  });

  describe('ChangeFromVirtual sub-component', () => {
    test('Displays ReadOnlyEmails', () => {
      // Run the test
      const { container, asFragment } = render(
        <ChangeFromVirtual
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expectHearingDateAndTime(screen);
      expect(screen.queryByRole('textbox', { name: 'Veteran Email' })).not.toBeInTheDocument();
      expect(screen.getByText('Veteran Email')).toBeInTheDocument();
      expect(screen.getAllByText(convertRegex(defaultHearing.appellantEmailAddress)).length).toBeGreaterThan(0);
      expect(screen.queryByRole('textbox', { name: 'POA/Representative Email' })).not.toBeInTheDocument();
      expect(screen.getByText('POA/Representative Email')).toBeInTheDocument();
      expect(screen.getAllByText(convertRegex(defaultHearing.representativeEmailAddress)).length).toBeGreaterThan(0);
      expect(asFragment()).toMatchSnapshot();
    });

    test('Displays Hearing Location when present', () => {
      // Run the test
      const { asFragment } = render(
        <ChangeFromVirtual
          update={updateSpy}
          hearing={{
            ...defaultHearing,
            location
          }}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expectHearingDateAndTime(screen);
      expect(screen.getByText('Location:')).toBeInTheDocument();
      expect(screen.getByText(location.name)).toBeInTheDocument();
      expect(screen.queryByRole('textbox', { name: 'Veteran Email' })).not.toBeInTheDocument();
      expect(screen.getByText('Veteran Email')).toBeInTheDocument();
      expect(screen.getAllByText(convertRegex(defaultHearing.appellantEmailAddress)).length).toBeGreaterThan(0);
      expect(screen.queryByRole('textbox', { name: 'POA/Representative Email' })).not.toBeInTheDocument();
      expect(screen.getByText('POA/Representative Email')).toBeInTheDocument();
      expect(screen.getAllByText(convertRegex(defaultHearing.representativeEmailAddress)).length).toBeGreaterThan(0);

      expect(asFragment()).toMatchSnapshot();
    });
  });

  describe('ChangeEmailOrTimezone sub-component', () => {
    test('Displays ReadOnlyEmails component', () => {
      // Run the test
      const { container, asFragment } = render(
        <ChangeEmailOrTimezone
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expect(screen.getByTestId('read-only-emails-testid')).toBeInTheDocument();
      expect(asFragment()).toMatchSnapshot();
    });
  });

  describe('ChangeHearingTime sub-component', () => {
    test('Displays ReadOnlyEmails component', () => {
      // Run the test
      const { asFragment } = render(
        <ChangeHearingTime
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expect(screen.getByTestId('datetime-testid')).toBeInTheDocument();
      expect(screen.getByTestId('read-only-emails-testid')).toBeInTheDocument();
      expectHearingDateAndTime(screen);
      expect(screen.queryByRole('textbox', { name: 'Veteran Email' })).not.toBeInTheDocument();
      expect(screen.getByText('Veteran Email')).toBeInTheDocument();
      expect(screen.getAllByText(convertRegex(defaultHearing.appellantEmailAddress)).length).toBeGreaterThan(0);
      expect(screen.queryByRole('textbox', { name: 'POA/Representative Email' })).not.toBeInTheDocument();
      expect(screen.getByText('POA/Representative Email')).toBeInTheDocument();
      expect(screen.getAllByText(convertRegex(defaultHearing.representativeEmailAddress)).length).toBeGreaterThan(0);
      expect(asFragment()).toMatchSnapshot();
    });
  });

  describe('DateTime sub-component', () => {
    test('Displays formatted hearing date and time', () => {
      // Run the test
      const {container, asFragment} = render(
        <DateTime
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expect(screen.getByTestId('datetime-testid')).toBeInTheDocument();
      expectHearingDateAndTime(screen);
      expect(container.querySelector('.cf-help-divider')).not.toBeInTheDocument();
      expect(asFragment()).toMatchSnapshot();
    });

    test('Displays divider for formerly Central hearings', () => {
      // Run the test
      const {container, asFragment} = render(
        <DateTime
          update={updateSpy}
          hearing={centralHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expect(container.querySelector('.cf-help-divider')).toBeInTheDocument();
      expect(asFragment()).toMatchSnapshot();
    });
  });

  const videoOrCentralExpectations = (hearing) => {
    test('Displays only appellant email when appellantEmailEdited', () => {
      // Run the test
      const {container, asFragment} = render(
        <ReadOnlyEmails
          appellantEmailEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expect(screen.getByTestId('read-only-emails-testid')).toBeInTheDocument();
      expectSingleEmailAssertion(screen, container, hearing);
      expect(asFragment()).toMatchSnapshot();
    });

    test('Displays only representative email when representativeEmailEdited', () => {
      // Run the test
      const {container, asFragment} = render(
        <ReadOnlyEmails
          representativeEmailEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expectSingleEmailAssertion(screen, container, hearing);
      expect(asFragment()).toMatchSnapshot();
    });

    test('Displays both representative email/time and appellant email/time when both timezones are edited', () => {
      // Run the test
      const {container, asFragment} = render(
        <ReadOnlyEmails
          appellantTzEdited
          representativeTzEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expectAllEmailsAssertion(screen, container, hearing);
      expect(asFragment()).toMatchSnapshot();
    });

    test('Displays both representative email/time and appellant email/time when showAllEmails is true', () => {
      // Run the test
      const {container, asFragment} = render(
        <ReadOnlyEmails
          showAllEmails
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expectAllEmailsAssertion(screen, container, hearing);
      expect(asFragment()).toMatchSnapshot();
    });

    test('Displays Section divider when appellant timezone and POA/Representative email edited', () => {
      // Run the test
      const {container, asFragment} = render(
        <ReadOnlyEmails
          appellantTzEdited
          representativeEmailEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expectAllEmailsAssertion(screen, container, hearing);
      expect(asFragment()).toMatchSnapshot();
    });

    test('Displays Section divider when appellant email and POA/Representative timezone edited', () => {
      // Run the test
      const {container, asFragment} = render(
        <ReadOnlyEmails
          appellantEmailEdited
          representativeTzEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expectAllEmailsAssertion(screen, container, hearing);
      expect(asFragment()).toMatchSnapshot();
    });

    test('Does not display Section divider when only appellant timezone edited', () => {
      // Run the test
      const {container, asFragment} = render(
        <ReadOnlyEmails
          appellantEmailEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expectSingleEmailAssertion(screen, container, hearing);
      expect(asFragment()).toMatchSnapshot();
    });

    test('Does not display Section divider when only POA/Representative timezone edited', () => {
      // Run the test
      const {container, asFragment} = render(
        <ReadOnlyEmails
          representativeTzEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expectSingleEmailAssertion(screen, container, hearing);
      expect(asFragment()).toMatchSnapshot();
    });
  };

  describe('ReadOnlyEmails sub-component', () => {
    describe('Formerly Video Virtual Hearing', () => {
      videoOrCentralExpectations(defaultHearing);
    });

    describe('Formerly Central Virtual Hearing', () => {
      videoOrCentralExpectations(centralHearing);
    });
  });
});
