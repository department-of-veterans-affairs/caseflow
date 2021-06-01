import React, { useState } from 'react';

import { HearingDaysNav } from './HearingDaysNav';
import { generateHearingDays } from '../../../../test/data/hearings';

export default {
  title: 'Hearings/Components/Assign Hearings/HearingDaysNav',
  component: HearingDaysNav,
  argTypes: {
    upcomingHearingDays: { table: { disable: true } },
    selectedHearingDay: { table: { disable: true } },
    onSelectedHearingDayChange: { table: { disable: true } },
  }
};

const Template = (args) => {
  const [selected, setSelected] = useState(0);
  const hearingDays = generateHearingDays('RO17', args.numberOfDays);

  return (
    <HearingDaysNav
      upcomingHearingDays={hearingDays}
      onSelectedHearingDayChange={(day) => setSelected(Object.values(hearingDays).indexOf(day))}
      selectedHearingDay={hearingDays[selected]}
    />
  );
};

export const Basic = Template.bind({});
Basic.args = {
  numberOfDays: 5,
};

Basic.argTypes = {
  numberOfDays: { control: { type: 'number' } },
};
