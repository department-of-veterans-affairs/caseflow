import React from 'react';

const SPECIAL_ISSUES = [
  {
    display: 'Contaminated Water at Camp LeJeune',
    specialIssue: 'contaminatedWaterAtCampLejeune',
    stationOfJurisdiction: '327 - Louisville, KY',
    unhandled: null
  },
  {
    display: 'DIC - death, or accrued benefits - United States',
    specialIssue: 'dicDeathOrAccruedBenefitsUnitedStates',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    }
  },
  {
    display: `Education - GI Bill, dependents educational assistance, ` +
      `scholarship, transfer of entitlement`,
    specialIssue: `educationGiBillDependentsEducationalAssistanceScholarship` +
      `TransferOfEntitlement`,
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: 'education',
      regionalOffice: 'education'
    }
  },
  {
    display: 'Foreign claim - compensation claims, dual claims, appeals',
    specialIssue: 'foreignClaimCompensationClaimsDualClaimsAppeals',
    stationOfJurisdiction: '311 - Pittsburgh, PA',
    unhandled: null
  },
  {
    display: 'Foreign pension, DIC - Mexico, Central and South America, Caribbean',
    specialIssue: 'foreignPensionDicMexicoCentralAndSouthAmericaCaribb',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: ['PMC/PMCIPC.VAVBASPL@va.gov', 'Hillary.Hernandez@va.gov'],
      regionalOffice: 'RO83'
    }
  },
  {
    display: 'Foreign pension, DIC - all other foreign countries',
    specialIssue: 'foreignPensionDicAllOtherForeignCountries',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddess: 'PMC',
      regionalOffice: 'PMC'
    }
  },
  {
    display: 'Hearing - including travel board & video conference',
    specialIssue: 'hearingIncludingTravelBoardVideoConference',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Home Loan Guaranty',
    specialIssue: 'homeLoanGuaranty',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: null,
      regionalOffice: null
    }
  },
  {
    display: 'Incarcerated Veterans',
    specialIssue: 'incarceratedVeterans',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Insurance',
    specialIssue: 'insurance',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: ['nancy.encarnado@va.gov'],
      regionalOffice: 'RO80'
    }
  },
  {
    display: 'Manlincon Compliance',
    node: <span><i>Manlincon</i> Compliance</span>,
    specialIssue: 'manlinconCompliance',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Mustard Gas',
    specialIssue: 'mustardGas',
    stationOfJurisdiction: '351 - Muskogee, OK',
    unhandled: null
  },
  {
    display: 'National Cemetery Administration',
    specialIssue: 'nationalCemeteryAdministration',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: null,
      regionalOffice: null
    }
  },
  {
    display: 'Non-rating issue',
    specialIssue: 'nonratingIssue',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Pension - United States',
    specialIssue: 'pensionUnitedStates',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    }
  },
  {
    display: 'Private Attorney or Agent',
    specialIssue: 'privateAttorneyOrAgent',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Radiation',
    specialIssue: 'radiation',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Rice Compliance',
    node: <span><i>Rice</i> Compliance</span>,
    specialIssue: 'riceCompliance',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Spina Bifida',
    specialIssue: 'spinaBifida',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: `U.S. Territory claim - American Samoa, Guam, Northern ` +
      `Mariana Islands (Rota, Saipan & Tinian)`,
    specialIssue: `usTerritoryClaimAmericanSamoaGuamNorthern` +
      `MarianaIslandsRotaSaipanTinian`,
    stationOfJurisdiction: '459 - Honolulu, HI',
    unhandled: null
  },
  {
    display: 'U.S. Territory claim - Philippines',
    specialIssue: 'usTerritoryClaimPhilippines',
    stationOfJurisdiction: '358 - Manila, Philippines',
    unhandled: null
  },
  {
    display: 'U.S. Territory claim - Puerto Rico and Virgin Islands',
    specialIssue: 'usTerritoryClaimPuertoRicoAndVirginIslands',
    stationOfJurisdiction: '355 - San Juan, Puerto Rico',
    unhandled: null
  },
  {
    display: 'VAMC',
    specialIssue: 'vamc',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: ['Travis.Richardson@va.gov'],
      regionalOffice: 'RO99'
    }
  },
  {
    display: 'Vocational Rehab',
    specialIssue: 'vocationalRehab',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: null,
      regionalOffice: null
    }
  },
  {
    display: 'Waiver of Overpayment',
    specialIssue: 'waiverOfOverpayment',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: 'COWC',
      regionalOffice: 'COWC'
    }
  }
];

export default SPECIAL_ISSUES;
