// import React from 'react';
// import StartHoldModal from './StartHoldModal';
// import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';
// import { onReceiveAmaTasks } from '../QueueActions';
// import {
//   requestSave,
//   resetErrorMessages,
//   resetSuccessMessages,
// } from '../uiReducer/uiActions';

// import { amaAppeal } from '../../../test/data/appeals';

// export default {
//   title: 'Queue/CaseTimeline/StartHoldModal',
//   component: StartHoldModal,
//   parameters: {
//     controls: { expanded: true },
//     docs: {
//       inlineStories: false,
//       iframeHeight: 600,
//     },
//   },

//   args: {
//     appeal: amaAppeal.veteranFullName,
//     appealId: amaAppeal.id,
//     onReceiveAmaTasks: { onReceiveAmaTasks },
//     requestSave: { requestSave },
//     resetSuccessMessages: { resetSuccessMessages },
//     resetErrorMessages: { resetErrorMessages },
//     task: {
//       taskId: '123',
//       type: 'AssessDocumentationTask'
//     },
//     title: 'On Hold Modal',
//     highlightFormItems: false,
//     pathAfterSubmit: '',
//     validateForm: {},
//     submit: {}
//   },
//   argTypes: {
//     closeHandler: { action: 'closed' },
//   },
// };

// const Template = ({ ...componentArgs }) => {
//   const storeArgs = {};

//   return (
//     <Wrapper {...storeArgs}>
//       <StartHoldModal
//         {...componentArgs}
//       />
//     </Wrapper>

//   );
// };

// export const Basic = Template.bind({});
