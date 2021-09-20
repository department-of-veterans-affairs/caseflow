---
title: Appeal Workflow
tags: ["workflow"]
weight: 1
---

# Appeal Workflow

{{< mermaid >}}
graph TD

V[Veteran] -->|claim| firstRO[DRO]
firstRO -->|claim decision| V

%% start(start appeal) -.- V
V -->|appeal forms| R(Regional Office)

subgraph -VBA-
    firstRO
    R --> choice{choice?}
    choice --> |Supp Claim| DRO[DRO]
    choice --> |HLR| DRO
end
DRO --> |decision| V
choice --> |Board appeal, NOD| docket{docket?}

choice --> |Legacy appeal, before AMA| Certification
Certification --> InActiv[Activation]
InActiv --> H[Hearing]

subgraph -Hearing-
    H[Hearing]
end

docket --> |Hearing| InH
docket --> |Evid Subm| In
docket --> |Direct Review| In

subgraph -Intake-
    InH(Intake for Hearing)
    In(Intake)
end

InH --> H[Hearing]
H --> Transcription

In --> VSO
In --> ACD[ACD]
VSO --> ACD[ACD]
Transcription --> ACD[ACD]
ACD --> JAT[Judge assigns]

InActiv --> JAT

subgraph -Decision-
    JAT --> AT[Attorney task]
    VLJSupport[VLJ support] -.- AT
    AT --> DR[Judge Decision Review]
end

DR --> |Appeal Decision| qr{QR?}
qr --> |yes| QR(Quality Review)
qr --> |no| D[Dispatch]
QR --> D
D --> |decision| VSat{Veteran satisfied?}
VSat --> |yes| Enact
VSat --> |no| repeat[SC, CAVC, MTV, reconsider]
{{< /mermaid >}}

## Appeal States

{{< mermaid >}}
graph TD
Vet_choosing
Vet_choosing --> forms_at_VBA
forms_at_VBA --> HLR
forms_at_VBA --> SC
forms_at_VBA --> Appeal
HLR --> Vet_choosing
SC --> Vet_choosing
Vet_choosing --> satisfied

Appeal --> at_Intake
at_Intake --> at_Hearing
at_Intake --> at_Decision
at_Hearing --> at_Decision
at_Decision --> at_QualityReview
at_QualityReview --> at_Dispatch
at_Decision --> at_Dispatch
at_Dispatch --> Dispatched
Dispatched --> Vet_dissatisfied[dissatisfied, restart]
Dispatched --> Enacted
Enacted --> Closed
{{< /mermaid >}}