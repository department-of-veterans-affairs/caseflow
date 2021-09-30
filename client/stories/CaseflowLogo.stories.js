import React from 'react';

import CaseflowLogo from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/CaseflowLogo';
import { LOGO_COLORS } from '../app/constants/AppConstants';

export default {
  title: 'Commons/Frontend Toolkit/CaseflowLogo',
  component: CaseflowLogo,
  decorators: [],
  args: {
    accentColor: LOGO_COLORS.DEFAULT.ACCENT,
    overlapColor: LOGO_COLORS.DEFAULT.OVERLAP,
  },
  argTypes: {
    accentColor: {
      control: {
        type: 'color'
      }
    },
    overlapColor: {
      control: { type: 'color' }
    }
  }
};

const Template = (args) => <CaseflowLogo {...args} />;

export const All = () => (
  <React.Fragment>
    <CaseflowLogo accentColor={LOGO_COLORS.DEFAULT.ACCENT} overlapColor={LOGO_COLORS.DEFAULT.OVERLAP} />
    <CaseflowLogo accentColor={LOGO_COLORS.CERTIFICATION.ACCENT} overlapColor={LOGO_COLORS.CERTIFICATION.OVERLAP} />
    <CaseflowLogo accentColor={LOGO_COLORS.DISPATCH.ACCENT} overlapColor={LOGO_COLORS.DISPATCH.OVERLAP} />
    <CaseflowLogo accentColor={LOGO_COLORS.EFOLDER.ACCENT} overlapColor={LOGO_COLORS.EFOLDER.OVERLAP} />
    <CaseflowLogo accentColor={LOGO_COLORS.HEARINGS.ACCENT} overlapColor={LOGO_COLORS.HEARINGS.OVERLAP} />
    <CaseflowLogo accentColor={LOGO_COLORS.INTAKE.ACCENT} overlapColor={LOGO_COLORS.INTAKE.OVERLAP} />
    <CaseflowLogo accentColor={LOGO_COLORS.QUEUE.ACCENT} overlapColor={LOGO_COLORS.QUEUE.OVERLAP} />
    <CaseflowLogo accentColor={LOGO_COLORS.READER.ACCENT} overlapColor={LOGO_COLORS.READER.OVERLAP} />
  </React.Fragment>
);

export const Generic = Template.bind({});

export const Certification = Template.bind({});
Certification.args = {
  accentColor: LOGO_COLORS.CERTIFICATION.ACCENT,
  overlapColor: LOGO_COLORS.CERTIFICATION.OVERLAP
};

export const Dispatch = Template.bind({});
Dispatch.args = {
  accentColor: LOGO_COLORS.DISPATCH.ACCENT,
  overlapColor: LOGO_COLORS.DISPATCH.OVERLAP
};

export const eFolder = Template.bind({});
eFolder.args = {
  accentColor: LOGO_COLORS.EFOLDER.ACCENT,
  overlapColor: LOGO_COLORS.EFOLDER.OVERLAP
};
eFolder.storyName = 'eFolder';

export const Hearings = Template.bind({});
Hearings.args = {
  accentColor: LOGO_COLORS.HEARINGS.ACCENT,
  overlapColor: LOGO_COLORS.HEARINGS.OVERLAP
};

export const Intake = Template.bind({});
Intake.args = {
  accentColor: LOGO_COLORS.INTAKE.ACCENT,
  overlapColor: LOGO_COLORS.INTAKE.OVERLAP
};

export const Queue = Template.bind({});
Queue.args = {
  accentColor: LOGO_COLORS.QUEUE.ACCENT,
  overlapColor: LOGO_COLORS.QUEUE.OVERLAP
};

export const Reader = Template.bind({});
Reader.args = {
  accentColor: LOGO_COLORS.READER.ACCENT,
  overlapColor: LOGO_COLORS.READER.OVERLAP
};
