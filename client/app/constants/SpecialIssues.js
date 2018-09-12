import React from 'react';

const SPECIAL_ISSUES = [
  {
    display: 'Contaminated Water at Camp LeJeune',
    specialIssue: 'contaminatedWaterAtCampLejeune',
    stationOfJurisdiction: {
      key: '327',
      location: 'Louisville, KY'
    },
    snakeCase: 'contaminated_water_at_camp_lejeune',
    unhandled: null
  },
  {
    display: 'DIC - death, or accrued benefits - United States',
    specialIssue: 'dicDeathOrAccruedBenefitsUnitedStates',
    stationOfJurisdiction: null,
    snakeCase: 'dic_death_or_accrued_benefits_united_states',
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    }
  },
  {
    display: 'Education - GI Bill, dependents educational assistance, ' +
      'scholarship, transfer of entitlement',
    specialIssue: 'educationGiBillDependentsEducationalAssistanceScholarship' +
      'TransferOfEntitlement',
    stationOfJurisdiction: null,
    snakeCase: 'education_gi_bill_dependents_educational_assistance_scholars',
    unhandled: {
      emailAddress: 'education',
      regionalOffice: 'education'
    }
  },
  {
    display: 'Foreign claim - compensation claims, dual claims, appeals',
    specialIssue: 'foreignClaimCompensationClaimsDualClaimsAppeals',
    stationOfJurisdiction: {
      key: '311',
      location: 'Pittsburgh, PA'
    },
    snakeCase: 'foreign_claim_compensation_claims_dual_claims_appeals',
    unhandled: null
  },
  {
    display: 'Foreign pension, DIC - Mexico, Central and South America, Caribbean',
    specialIssue: 'foreignPensionDicMexicoCentralAndSouthAmericaCaribb',
    stationOfJurisdiction: null,
    snakeCase: 'foreign_pension_dic_mexico_central_and_south_america_caribb',
    unhandled: {
      emailAddress: ['AppealsPMC.VAVBASPL@va.gov', 'Hillary.Hernandez@va.gov'],
      regionalOffice: 'RO83'
    }
  },
  {
    display: 'Foreign pension, DIC - all other foreign countries',
    specialIssue: 'foreignPensionDicAllOtherForeignCountries',
    stationOfJurisdiction: null,
    snakeCase: 'foreign_pension_dic_all_other_foreign_countries',
    unhandled: {
      emailAddess: 'PMC',
      regionalOffice: 'PMC'
    }
  },
  {
    display: 'Hearing - including travel board & video conference',
    specialIssue: 'hearingIncludingTravelBoardVideoConference',
    stationOfJurisdiction: 'regional',
    snakeCase: 'hearing_including_travel_board_video_conference',
    unhandled: null
  },
  {
    display: 'Home Loan Guaranty',
    specialIssue: 'homeLoanGuaranty',
    stationOfJurisdiction: null,
    snakeCase: 'home_loan_guaranty',
    unhandled: {
      emailAddress: ['jennifer.Tillery@va.gov'],
      regionalOffice: 'RO88'
    }
  },
  {
    display: 'Incarcerated Veterans',
    specialIssue: 'incarceratedVeterans',
    stationOfJurisdiction: 'regional',
    snakeCase: 'incarcerated_veterans',
    unhandled: null
  },
  {
    display: 'Insurance',
    specialIssue: 'insurance',
    stationOfJurisdiction: null,
    snakeCase: 'insurance',
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
    snakeCase: 'manlincon_compliance',
    unhandled: null
  },
  {
    display: 'Mustard Gas',
    specialIssue: 'mustardGas',
    stationOfJurisdiction: {
      key: '351',
      location: 'Muskogee, OK'
    },
    snakeCase: 'mustard_gas',
    unhandled: null
  },
  {
    display: 'National Cemetery Administration',
    specialIssue: 'nationalCemeteryAdministration',
    stationOfJurisdiction: null,
    snakeCase: 'national_cemetery_administration',
    unhandled: {
      emailAddress: ['richard.byersII@va.gov'],
      regionalOffice: 'RO98'
    }
  },
  {
    display: 'Non-rating issue',
    specialIssue: 'nonratingIssue',
    stationOfJurisdiction: 'regional',
    snakeCase: 'nonrating_issue',
    unhandled: null
  },
  {
    display: 'Pension - United States',
    specialIssue: 'pensionUnitedStates',
    stationOfJurisdiction: null,
    snakeCase: 'pension_united_states',
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    }
  },
  {
    display: 'Private Attorney or Agent',
    specialIssue: 'privateAttorneyOrAgent',
    stationOfJurisdiction: null,
    snakeCase: 'private_attorney_or_agent',
    unhandled: null
  },
  {
    display: 'Radiation',
    specialIssue: 'radiation',
    stationOfJurisdiction: 'regional',
    snakeCase: 'radiation',
    unhandled: null
  },
  {
    display: 'Rice Compliance',
    node: <span><i>Rice</i> Compliance</span>,
    specialIssue: 'riceCompliance',
    stationOfJurisdiction: 'regional',
    snakeCase: 'rice_compliance',
    unhandled: null
  },
  {
    display: 'Spina Bifida',
    specialIssue: 'spinaBifida',
    stationOfJurisdiction: 'regional',
    snakeCase: 'spina_bifida',
    unhandled: null
  },
  {
    display: 'U.S. Territory claim - American Samoa, Guam, Northern ' +
      'Mariana Islands (Rota, Saipan & Tinian)',
    specialIssue: 'usTerritoryClaimAmericanSamoaGuamNorthern' +
      'MarianaIslandsRotaSaipanTinian',
    stationOfJurisdiction: {
      key: '459',
      location: 'Honolulu, HI'
    },
    snakeCase: 'us_territory_claim_american_samoa_guam_northern_mariana_isla',
    unhandled: null
  },
  {
    display: 'U.S. Territory claim - Philippines',
    specialIssue: 'usTerritoryClaimPhilippines',
    stationOfJurisdiction: {
      key: '358',
      location: 'Manila, Philippines'
    },
    snakeCase: 'us_territory_claim_philippines',
    unhandled: null
  },
  {
    display: 'U.S. Territory claim - Puerto Rico and Virgin Islands',
    specialIssue: 'usTerritoryClaimPuertoRicoAndVirginIslands',
    stationOfJurisdiction: {
      key: '355',
      location: 'San Juan, Puerto Rico'
    },
    snakeCase: 'us_territory_claim_puerto_rico_and_virgin_islands',
    unhandled: null
  },
  {
    display: 'VAMC',
    specialIssue: 'vamc',
    stationOfJurisdiction: null,
    snakeCase: 'vamc',
    unhandled: {
      emailAddress: ['Travis.Richardson@va.gov'],
      regionalOffice: 'RO99'
    }
  },
  {
    display: 'Vocational Rehab',
    specialIssue: 'vocationalRehab',
    snakeCase: 'vocational_rehab',
    stationOfJurisdiction: 'regional'
  },
  {
    display: 'Waiver of Overpayment',
    specialIssue: 'waiverOfOverpayment',
    stationOfJurisdiction: null,
    snakeCase: 'waiver_of_overpayment',
    unhandled: {
      emailAddress: 'COWC',
      regionalOffice: 'COWC'
    }
  }
];

export default SPECIAL_ISSUES;
