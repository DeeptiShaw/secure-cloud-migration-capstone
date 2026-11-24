# Monitoring plan
ALB 5xx/request >1% or p95 latency >1s for 5 minutes; EC2 CPU >70% for 5 minutes; RDS CPU >80% or free storage <20 GB initially (100 GB allocation). Configure SNS notification and test delivery. Enable CloudTrail multi-region management events, GuardDuty and VPC Flow Logs; retain logs 90 days initially. All alarm states pending verification.
