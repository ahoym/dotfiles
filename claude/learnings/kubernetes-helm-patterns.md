Helm app bootstrapping patterns — copying existing charts, inherited boilerplate gotchas, and placeholder alerting rules.
- **Keywords:** helm, kubernetes, bootstrap, chart copy, prometheusrule, placeholder alerts, values.yaml, prometheus: false, inherited boilerplate
- **Related:** none

---

## Disable Placeholder PrometheusRule When Bootstrapping New Helm Apps

When bootstrapping a new Helm app by copying an existing one, disable inherited placeholder prometheusrule boilerplate (`prometheus: false` in values.yaml) until real alerting rules are written. Placeholder rules (dummy alerts, wrong metric selectors) will be deployed and misfire in production if left enabled.
