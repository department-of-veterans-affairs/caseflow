import React from 'react';

import { EmailNotificationHistory } from 'app/hearings/components/details/EmailNotificationHistory';
import { TranscriptionFormSection } from 'app/hearings/components/details/TranscriptionFormSection';
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import { mount } from 'enzyme';
import CheckBox from 'app/components/Checkbox';
import DetailsForm from 'app/hearings/components/details/DetailsForm';
import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import { anyUser, amaHearing, defaultHearing } from 'test/data';

describe('DetailsForm', () => {
  test('Matches snapshot with default props when passed in', () => {
    const form = mount(
      <DetailsForm
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: hearingDetailsWrapper(anyUser, amaHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    expect(form).toMatchSnapshot();
    expect(form.find(EmailNotificationHistory)).toHaveLength(0);
  });

  test('Matches snapshot with for legacy hearing', () => {
    const form = mount(
      <DetailsForm
        isLegacy
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: hearingDetailsWrapper(anyUser, amaHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    expect(form).toMatchSnapshot();
    expect(form.find(HearingTypeDropdown)).toHaveLength(1);
    expect(form.find(TranscriptionFormSection)).toHaveLength(0);
  });

  test('Matches snapshot with for AMA hearing', () => {
    const form = mount(
      <DetailsForm
        isLegacy={false}
        hearing={defaultHearing}
      />,
      {
        wrappingComponent: hearingDetailsWrapper(anyUser, amaHearing),
        wrappingComponentProps: { store: detailsStore }
      }
    );

    expect(form).toMatchSnapshot();
    expect(form.find(HearingTypeDropdown)).toHaveLength(1);
    expect(form.find(TranscriptionFormSection)).toHaveLength(1);
    expect(
      form.findWhere((node) => node.props().name === 'evidenceWindowWaived' && node.type() === CheckBox)
    ).toHaveLength(1);
  });
});
