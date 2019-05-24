import HEARING_DISPOSITION_TYPES from '../../constants/HEARING_DISPOSITION_TYPES.json';

export const namePartToSortBy = (fullName) => {
  const nameParts = fullName.split(' ');

  switch (nameParts.length) {
  case 2:
    return nameParts[1];
  case 3:
    return nameParts[2];
  default:
    return fullName;
  }
};

export const fullNameParts = (fullName) => {
  const nameParts = fullName.split(' ');

  switch (nameParts.length) {
  case 2:
    return { lastName: nameParts[1],
      firstName: nameParts[0],
      middleName: '' };
  case 3:
    return { lastName: nameParts[2],
      firstName: nameParts[0],
      middleName: nameParts[1] };
  case 4:
    return { lastName: `${nameParts[2]} ${nameParts[3]}`,
      firstName: nameParts[0],
      middleName: nameParts[1] };
  default:
    return { lastName: fullName,
      firstName: '',
      middleName: '' };
  }
};

export const isPreviouslyScheduledHearing = (hearing) => (
  hearing.disposition === HEARING_DISPOSITION_TYPES.postponed ||
    hearing.disposition === HEARING_DISPOSITION_TYPES.cancelled
);
