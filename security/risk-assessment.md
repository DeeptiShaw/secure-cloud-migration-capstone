# Risk register
Likelihood × impact (1–5 each); residual scores are projected.
| Threat | Initial | Control | Residual |
|---|---:|---|---:|
| Credential theft |20|MFA, roles|10|
| SQL injection |20|Parameters, WAF|5|
| Data exposure |15|Private DB, KMS, TLS|5|
| DDoS |16|WAF, Shield, scaling|8|
| Unpatched software |16|Patch and scan|8|
| AZ failure |15|Multi-AZ, backups|5|
High residual risks require formal acceptance.
