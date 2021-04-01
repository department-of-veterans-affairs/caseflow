import React from 'react';
import { mount } from 'enzyme';

import VirtualHearingModal, {
  ChangeHearingTime,
  ChangeToVirtual,
  ChangeFromVirtual,
  ChangeEmailOrTimezone
  , DateTime, ReadOnlyEmails } from 'app/hearings/components/VirtualHearingModal';
import { defaultHearing, virtualHearing } from 'test/data';
import { HEARING_CONVERSION_TYPES } from 'app/hearings/constants';
import Button from 'app/components/Button';
import moment from 'moment-timezone';

import TextField from 'app/components/TextField';
import { zoneName } from 'app/hearings/utils';
import { centralHearing } from 'test/data/hearings';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';

// Setup the test constants
const updateSpy = jest.fn();
const error = 'Something went wrong...';
const location = { name: 'Somewhere' };

// Helper test to check email assertions on formerly central hearings
const showAllEmailsAssertion = (node, hearing) => {
  expect(node.find(ReadOnly)).toHaveLength(4);
  expect(node.find(ReadOnly).first().
    text()).toContain(zoneName(hearing.scheduledTimeString, virtualHearing.virtualHearing.appellantTz));
  expect(node.find(ReadOnly).at(1).
    text()).toContain(virtualHearing.virtualHearing.appellantEmail);
  expect(node.find(ReadOnly).at(2).
    text()).toContain(zoneName(hearing.scheduledTimeString, virtualHearing.virtualHearing.representativeTz));
  expect(node.find(ReadOnly).at(3).
    text()).toContain(virtualHearing.virtualHearing.representativeEmail);
  expect(node.find('.cf-help-divider')).toHaveLength(1);
};

const showSingleEmailAssertion = (node, hearing, email, tz) => {
  expect(node.find(ReadOnly)).toHaveLength(2);
  expect(node.find(ReadOnly).first().
    text()).toContain(zoneName(hearing.scheduledTimeString, tz));
  expect(node.find(ReadOnly).at(1).
    text()).toContain(email);
  expect(node.find('.cf-help-divider')).toHaveLength(0);
};

describe('VirtualHearingModal', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const modal = mount(
      <VirtualHearingModal
        update={updateSpy}
        hearing={defaultHearing}
        virtualHearing={virtualHearing.virtualHearing}
        type={HEARING_CONVERSION_TYPES[0]}
      />);

    // Assertions
    expect(modal.find(ChangeToVirtual)).toHaveLength(1);
    expect(modal.find(ChangeToVirtual).prop('hearing')).toEqual(defaultHearing);
    expect(modal.find(ChangeToVirtual).prop('virtualHearing')).toEqual(virtualHearing.virtualHearing);
    expect(modal.find(Button).first().
      text()).toEqual('Change and Send Email');
    expect(modal.find(Button).at(1).
      text()).toEqual('Cancel');
    expect(modal).toMatchSnapshot();
  });

  test('Displays ChangeFromVirtual component when type is change_from_virtual', () => {
    // Run the test
    const modal = mount(
      <VirtualHearingModal
        update={updateSpy}
        hearing={defaultHearing}
        virtualHearing={virtualHearing.virtualHearing}
        type={HEARING_CONVERSION_TYPES[1]}
      />);

    // Assertions
    expect(modal.find(ChangeFromVirtual)).toHaveLength(1);
    expect(modal.find(ChangeFromVirtual).prop('hearing')).toEqual(defaultHearing);
    expect(modal.find(ChangeFromVirtual).prop('virtualHearing')).toEqual(virtualHearing.virtualHearing);
    expect(modal.find(Button).first().
      text()).toEqual('Change and Send Email');
    expect(modal.find(Button).at(1).
      text()).toEqual('Cancel');
    expect(modal).toMatchSnapshot();
  });

  test('Displays ChangeEmailOrTimezone component when type is change_email_or_timezone', () => {
    // Run the test
    const modal = mount(
      <VirtualHearingModal
        update={updateSpy}
        hearing={defaultHearing}
        virtualHearing={virtualHearing.virtualHearing}
        type={HEARING_CONVERSION_TYPES[2]}
      />);

    // Assertions
    expect(modal.find(ChangeEmailOrTimezone)).toHaveLength(1);
    expect(modal.find(ChangeEmailOrTimezone).prop('hearing')).toEqual(defaultHearing);
    expect(modal.find(ChangeEmailOrTimezone).prop('virtualHearing')).toEqual(virtualHearing.virtualHearing);
    expect(modal.find(Button).first().
      text()).toEqual('Update and Send Email');
    expect(modal.find(Button).at(1).
      text()).toEqual('Cancel');
    expect(modal).toMatchSnapshot();
  });

  test('Displays ChangeHearingTime component when type is change_hearing_time', () => {
    // Run the test
    const modal = mount(
      <VirtualHearingModal
        update={updateSpy}
        hearing={defaultHearing}
        virtualHearing={virtualHearing.virtualHearing}
        type={HEARING_CONVERSION_TYPES[3]}
      />);

    // Assertions
    expect(modal.find(ChangeHearingTime)).toHaveLength(1);
    expect(modal.find(ChangeHearingTime).prop('hearing')).toEqual(defaultHearing);
    expect(modal.find(ChangeHearingTime).prop('virtualHearing')).toEqual(virtualHearing.virtualHearing);
    expect(modal.find(Button).first().
      text()).toEqual('Update Hearing Time');
    expect(modal.find(Button).at(1).
      text()).toEqual('Cancel');
    expect(modal).toMatchSnapshot();
  });

  describe('ChangeToVirtual sub-component', () => {
    test('Displays input for appellant and representative email', () => {
      // Run the test
      const changeToVirtual = mount(
        <ChangeToVirtual
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />);

      // Assertions
      expect(changeToVirtual.find(DateTime)).toHaveLength(1);
      expect(changeToVirtual.find(TextField).first().
        prop('value')).toEqual(virtualHearing.virtualHearing.appellantEmail);
      expect(changeToVirtual.find(TextField).at(1).
        prop('value')).toEqual(virtualHearing.virtualHearing.representativeEmail);
      expect(changeToVirtual).toMatchSnapshot();
    });

    test('Displays appellant email error when present', () => {
      // Run the test
      const changeToVirtual = mount(
        <ChangeToVirtual
          appellantEmailError={error}
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />);

      // Assertions
      expect(changeToVirtual.find('.usa-input-error-message').text()).toEqual(error);
      expect(changeToVirtual).toMatchSnapshot();
    });

    test('Displays representative email error when present', () => {
      // Run the test
      const changeToVirtual = mount(
        <ChangeToVirtual
          representativeEmailError={error}
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />);

      // Assertions
      expect(changeToVirtual.find('.usa-input-error-message').text()).toEqual(error);
      expect(changeToVirtual).toMatchSnapshot();
    });
  });

  describe('ChangeFromVirtual sub-component', () => {
    test('Displays ReadOnlyEmails', () => {
      // Run the test
      const changeFromVirtual = mount(
        <ChangeFromVirtual
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expect(changeFromVirtual.children()).toHaveLength(2);
      expect(changeFromVirtual.find(DateTime)).toHaveLength(1);
      expect(changeFromVirtual.find(ReadOnlyEmails)).toHaveLength(1);
      expect(changeFromVirtual).toMatchSnapshot();
    });

    test('Displays Hearing Location when present', () => {
      // Run the test
      const changeFromVirtual = mount(
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
      expect(changeFromVirtual.children()).toHaveLength(3);
      expect(changeFromVirtual.childAt(1).text()).toContain(location.name);
      expect(changeFromVirtual.childAt(1).find('strong').
        text()).toContain('Location');
      expect(changeFromVirtual.find(DateTime)).toHaveLength(1);
      expect(changeFromVirtual.find(ReadOnlyEmails)).toHaveLength(1);
      expect(changeFromVirtual).toMatchSnapshot();
    });
  });

  describe('ChangeEmailOrTimezone sub-component', () => {
    test('Displays ReadOnlyEmails component', () => {
      // Run the test
      const changeEmail = mount(
        <ChangeEmailOrTimezone
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expect(changeEmail.find(ReadOnlyEmails)).toHaveLength(1);
      expect(changeEmail).toMatchSnapshot();
    });
  });

  describe('ChangeHearingTime sub-component', () => {
    test('Displays ReadOnlyEmails component', () => {
      // Run the test
      const changeHearingTime = mount(
        <ChangeHearingTime
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expect(changeHearingTime.find(DateTime)).toHaveLength(1);
      expect(changeHearingTime.find(ReadOnlyEmails)).toHaveLength(1);
      expect(changeHearingTime.find(ReadOnlyEmails).prop('showAllEmails')).toEqual(true);
      expect(changeHearingTime).toMatchSnapshot();
    });
  });

  describe('DateTime sub-component', () => {
    test('Displays formatted hearing date and time', () => {
      // Run the test
      const dateTime = mount(
        <DateTime
          update={updateSpy}
          hearing={defaultHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expect(dateTime.find('strong').first().
        text()).toContain('Hearing Date');
      expect(dateTime.find('strong').at(1).
        text()).toContain('Hearing Time');
      expect(dateTime.text()).toContain(moment(defaultHearing.scheduledFor).format('MM/DD/YYYY'));
      expect(dateTime.text()).toContain(zoneName(defaultHearing.scheduledTimeString));
      expect(dateTime.find('.cf-help-divider')).toHaveLength(0);
      expect(dateTime).toMatchSnapshot();
    });

    test('Displays divider for formerly Central hearings', () => {
      // Run the test
      const dateTime = mount(
        <DateTime
          update={updateSpy}
          hearing={centralHearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      expect(dateTime.find('.cf-help-divider')).toHaveLength(1);
      expect(dateTime).toMatchSnapshot();
    });
  });

  const videoOrCentralExpectations = (hearing) => {
    test('Displays only appellant email when appellantEmailEdited', () => {
      // Run the test
      const readOnlyEmails = mount(
        <ReadOnlyEmails
          appellantEmailEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      showSingleEmailAssertion(
        readOnlyEmails,
        hearing,
        virtualHearing.virtualHearing.appellantEmail,
        virtualHearing.virtualHearing.appellantTz
      );
      expect(readOnlyEmails).toMatchSnapshot();
    });

    test('Displays only representative email when representativeEmailEdited', () => {
      // Run the test
      const readOnlyEmails = mount(
        <ReadOnlyEmails
          representativeEmailEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      showSingleEmailAssertion(
        readOnlyEmails,
        hearing,
        virtualHearing.virtualHearing.representativeEmail,
        virtualHearing.virtualHearing.representativeTz
      );
      expect(readOnlyEmails).toMatchSnapshot();
    });

    test('Displays both representative email/time and appellant email/time when both timezones are edited', () => {
      // Run the test
      const readOnlyEmails = mount(
        <ReadOnlyEmails
          appellantTzEdited
          representativeTzEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      showAllEmailsAssertion(readOnlyEmails, hearing);
      expect(readOnlyEmails).toMatchSnapshot();
    });

    test('Displays both representative email/time and appellant email/time when showAllEmails is true', () => {
      // Run the test
      const readOnlyEmails = mount(
        <ReadOnlyEmails
          showAllEmails
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      showAllEmailsAssertion(readOnlyEmails, hearing);
      expect(readOnlyEmails).toMatchSnapshot();
    });

    test('Displays Section divider when appellant timezone and POA/Representative email edited', () => {
      // Run the test
      const readOnlyEmails = mount(
        <ReadOnlyEmails
          appellantTzEdited
          representativeEmailEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      showAllEmailsAssertion(readOnlyEmails, hearing);
      expect(readOnlyEmails).toMatchSnapshot();
    });

    test('Displays Section divider when appellant email and POA/Representative timezone edited', () => {
      // Run the test
      const readOnlyEmails = mount(
        <ReadOnlyEmails
          appellantEmailEdited
          representativeTzEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      showAllEmailsAssertion(readOnlyEmails, hearing);
      expect(readOnlyEmails).toMatchSnapshot();
    });

    test('Does not display Section divider when only appellant timezone edited', () => {
      // Run the test
      const readOnlyEmails = mount(
        <ReadOnlyEmails
          appellantEmailEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      showSingleEmailAssertion(
        readOnlyEmails,
        hearing,
        virtualHearing.virtualHearing.appellantEmail,
        virtualHearing.virtualHearing.appellantTz
      );
      expect(readOnlyEmails).toMatchSnapshot();
    });

    test('Does not display Section divider when only POA/Representative timezone edited', () => {
      // Run the test
      const readOnlyEmails = mount(
        <ReadOnlyEmails
          representativeTzEdited
          update={updateSpy}
          hearing={hearing}
          virtualHearing={virtualHearing.virtualHearing}
        />
      );

      // Assertions
      showSingleEmailAssertion(
        readOnlyEmails,
        hearing,
        virtualHearing.virtualHearing.representativeEmail,
        virtualHearing.virtualHearing.representativeTz
      );
      expect(readOnlyEmails).toMatchSnapshot();
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
