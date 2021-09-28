---
title: ETL/ODS
menu:
  navmenu:
    identifier: etl
    collapsible: true
weight: 2
---

# ETL / ODS Database

- [Data Architecture](https://github.com/department-of-veterans-affairs/caseflow/wiki/Data-Architecture)
- [ETL Schema CSV](/schema/etl_schema_csv)

## Database Dataflow Diagram

{{< mermaid >}}
flowchart TD
subgraph prod["(Production Environment)"]
    VBMS[[VBMS]] -.- Caseflow_App[Caseflow Rails App]
    BGS[[BGS]] -.- Caseflow_App
    Caseflow_App -.- VACOLS[("VACOLS<br/>transactional DB<br/>(Oracle)")]
    Caseflow_App -- Rails --> Caseflow[("Caseflow<br/>transactional DB<br/>(Postgres)")]
end
style Replicas fill:#ddd,stroke:#333,stroke-width:2px
subgraph Replicas[" "]
    style Replicas_label fill:#ddd,stroke:#ddd,font-size:10px,font-weight: bold
    Replicas_label["(Replicas)"]
    VACOLS -- DMS --> VACOLS_replica[("VACOLS copy<br/>(Oracle)")]
    Caseflow -- Pg --> Caseflow_replica[("Caseflow replica<br/>(RDS Postgres)")]
    Caseflow -- "Rails (ETL)" --> ODS[("ODS<br/>(RDS Postgres)")]
end

style Metabase fill:#0ff,stroke:#333,stroke-width:2px
Replicas -.-> Metabase{{Metabase}}

style Redshift fill:pink,stroke:#333,stroke-width:2px
subgraph Redshift[" "]
    style Redshift_label fill:pink,stroke:pink,stroke-width:2px
    Redshift_label["(Redshift)"]
    RS_CF_replica(('public'))
    RS_ODS(('ods'))
    RS_VACOLS_replica(('vacols'))
end
Caseflow -- DMS --> RS_CF_replica
ODS -- DMS --> RS_ODS
VACOLS_replica -- DMS --> RS_VACOLS_replica

style Tableau fill:#f9f,stroke:#333,stroke-width:2px
Redshift -.-> Tableau{{Tableau}}
{{</ mermaid >}}


