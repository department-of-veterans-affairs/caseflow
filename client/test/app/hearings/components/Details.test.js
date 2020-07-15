import React from 'react';

import { EmailNotificationHistory } from 'app/hearings/components/details/EmailNotificationHistory';
import { TranscriptionFormSection } from 'app/hearings/components/details/TranscriptionFormSection';
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import { mount } from 'enzyme';
import CheckBox from 'app/components/Checkbox';
import DetailsForm from 'app/hearings/components/details/DetailsForm';
import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import { userWithVirtualHearingsFeatureEnabled, anyUser, amaHearing, defaultHearing } from 'test/data';

describe('Details', () => {
  test('Matches snapshot with default props', () => {

  });
})
;
