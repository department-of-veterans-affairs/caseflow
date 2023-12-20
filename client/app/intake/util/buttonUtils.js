// ButtonUtils.js
export const generateSkipButton = (btns, props) => {
  if (props.onSkip) {
    btns.push({
      classNames: ['usa-button', 'usa-button-secondary', 'no-matching-issues'],
      name: props.skipText,
      onClick: props.onSkip
    });
  }

  return btns;
};
